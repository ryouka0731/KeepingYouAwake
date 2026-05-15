//
//  KYAScripting.m
//  KeepingYouAwake
//

#import "KYAScripting.h"
#import <KYAApplicationSupport/KYAApplicationSupport.h>
#import <KYACommon/KYACommon.h>

#pragma mark - URL-scheme bridge

/// Class-level URL dispatcher seam. The three AppleScript command
/// classes call into a single helper that delegates to this block. In
/// production this is nil — the helper falls back to the default
/// Launch Services path. Tests inject a capturing block via
/// `+[KYAScriptingProxy kya_setURLDispatcherForTesting:]` so the URL
/// can be asserted on without actually opening anything.
///
/// Access is guarded by a queue because AppleScript commands may be
/// dispatched on the main thread while a test set the block on the
/// test queue.
static KYAScriptingURLDispatcher gKYAScriptingURLDispatcher = nil;

static dispatch_queue_t KYAScriptingDispatcherQueue(void)
{
    static dispatch_queue_t queue;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        queue = dispatch_queue_create("info.marcel-dierkes.KeepingYouAwake.scripting.dispatcher",
                                      DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

static KYAScriptingURLDispatcher KYAScriptingCurrentDispatcher(void)
{
    __block KYAScriptingURLDispatcher current = nil;
    dispatch_sync(KYAScriptingDispatcherQueue(), ^{
        current = gKYAScriptingURLDispatcher;
    });
    return current;
}

static void KYAScriptingPostURL(NSString *url)
{
    NSURL *target = [NSURL URLWithString:url];
    if(target == nil) { return; }
    KYAScriptingURLDispatcher dispatcher = KYAScriptingCurrentDispatcher();
    if(dispatcher != nil)
    {
        dispatcher(target);
        return;
    }
    // -openURL: was deprecated in 10.15. Use the modern
    // openURL:configuration:completionHandler: form. Even though both
    // round-trip through Launch Services for a self-targeted URL, the
    // modern variant is non-deprecated and asynchronous (we don't
    // need the result), so it's strictly nicer than the old API.
    [NSWorkspace.sharedWorkspace openURL:target
                           configuration:[NSWorkspaceOpenConfiguration configuration]
                       completionHandler:nil];
}

#pragma mark - Commands

// Notes on return-value semantics:
// `openURL:configuration:completionHandler:` is asynchronous, so when
// these commands return, the actual activation state hasn't propagated
// yet. Reading the live state in this same method (e.g. wasActive
// before deactivate) is a TOCTOU race against any other automation
// client. Instead we report the boolean "the command was dispatched"
// — and the SDEF documents it that way. A caller who needs to know
// the resulting state should read `kya.active` after a brief delay
// (the proxy's 1-second TTL cache makes that cheap).

@implementation KYAActivateScriptCommand
- (id)performDefaultImplementation
{
    NSDictionary *args = self.evaluatedArguments;
    NSNumber *durationArg = args[@"Duration"];
    NSInteger seconds = 0;
    if([durationArg isKindOfClass:NSNumber.class])
    {
        seconds = durationArg.integerValue;
    }
    // SDEF contract: omit / 0 / negative duration = indefinite. The
    // URL scheme treats `seconds=0` as KYASleepWakeTimeIntervalIndefinite
    // explicitly; an absent `seconds` parameter would fall through to
    // KYAAppController's defaultTimeInterval (whatever the user picked
    // in the menu), which is *not* indefinite. So always pass an
    // explicit seconds value.
    if(seconds < 0) { seconds = 0; }
    KYAScriptingPostURL([NSString stringWithFormat:@"keepingyouawake:///activate?seconds=%ld", (long)seconds]);
    return @YES;
}
@end

@implementation KYADeactivateScriptCommand
- (id)performDefaultImplementation
{
    KYAScriptingPostURL(@"keepingyouawake:///deactivate");
    return @YES;
}
@end

@implementation KYAToggleScriptCommand
- (id)performDefaultImplementation
{
    KYAScriptingPostURL(@"keepingyouawake:///toggle");
    return @YES;
}
@end

#pragma mark - Proxy

@interface KYAScriptingProxy ()
@property (nonatomic, nullable) KYAActivityLogEntry *cachedOpenEntry;
@property (nonatomic) NSTimeInterval cacheStampedAt;
@end

@implementation KYAScriptingProxy

+ (instancetype)sharedProxy
{
    static dispatch_once_t once;
    static KYAScriptingProxy *shared;
    dispatch_once(&once, ^{ shared = [self new]; });
    return shared;
}

/// Cache TTL for the open-entry lookup. AppleScript property accessors
/// (`active`, `remaining seconds`, `source`) are typically polled in
/// quick succession; a 1-second TTL collapses three reads into one
/// disk hit while keeping the data fresh enough for human-perceived
/// state changes.
static const NSTimeInterval KYAScriptingProxyCacheTTL = 1.0;

- (nullable KYAActivityLogEntry *)mostRecentOpenEntry
{
    NSTimeInterval now = [NSDate date].timeIntervalSinceReferenceDate;
    if(self.cachedOpenEntry != nil && (now - self.cacheStampedAt) < KYAScriptingProxyCacheTTL)
    {
        return self.cachedOpenEntry;
    }

    Auto entries = [KYAActivityLogger.sharedLogger recentEntriesWithLimit:50];
    // The activity log holds at most one open entry at a time (entry
    // is opened on activateTimer:, closed on terminateTimer / natural
    // expiration). So the open entry, if any, is necessarily the
    // most-recent activate, well within the 50-entry window.

    // Stale-entry guard: if KYA crashed or was force-quit during a
    // session, its open entry survives in the JSONL. After a restart
    // we'd happily call that "active" — false. Only trust an open
    // entry if it was started AFTER the current process launched.
    NSDate *launchDate = NSRunningApplication.currentApplication.launchDate;

    KYAActivityLogEntry *found = nil;
    for(KYAActivityLogEntry *entry in entries)
    {
        if(entry.endedAt != nil) { continue; }
        if(launchDate != nil && [entry.startedAt compare:launchDate] == NSOrderedAscending)
        {
            // Stale from a prior process. Skip.
            continue;
        }
        found = entry;
        break;
    }

    self.cachedOpenEntry = found;
    self.cacheStampedAt = now;
    return found;
}

- (BOOL)isActive
{
    return [self mostRecentOpenEntry] != nil;
}

- (NSInteger)remainingSeconds
{
    KYAActivityLogEntry *entry = [self mostRecentOpenEntry];
    if(entry == nil) { return -1; }
    if(entry.requestedDuration <= 0) { return -1; }
    NSTimeInterval elapsed = -[entry.startedAt timeIntervalSinceNow];
    NSTimeInterval remaining = entry.requestedDuration - elapsed;
    if(remaining <= 0) { return 0; }
    // ceil so a script reading "remaining seconds" while the actual
    // remaining is e.g. 30.4 doesn't see 30 (and then re-poll a moment
    // later still seeing 30, looking like the timer froze).
    return (NSInteger)ceil(remaining);
}

- (NSString *)source
{
    KYAActivityLogEntry *entry = [self mostRecentOpenEntry];
    if(entry == nil) { return @""; }
    return entry.source ?: @"";
}

@end

#pragma mark - Testing seam

@implementation KYAScriptingProxy (Testing)

+ (void)kya_setURLDispatcherForTesting:(KYAScriptingURLDispatcher _Nullable)dispatcher
{
    // Copy onto the heap so the caller can pass a stack block literal.
    KYAScriptingURLDispatcher copied = [dispatcher copy];
    dispatch_sync(KYAScriptingDispatcherQueue(), ^{
        gKYAScriptingURLDispatcher = copied;
    });
}

@end

#pragma mark - NSApplication scripting hook

@interface NSApplication (KYAScripting)
- (KYAScriptingProxy *)scriptingProxy;
@end

@implementation NSApplication (KYAScripting)
- (KYAScriptingProxy *)scriptingProxy
{
    return KYAScriptingProxy.sharedProxy;
}
@end
