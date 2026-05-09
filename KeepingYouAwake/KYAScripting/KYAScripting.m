//
//  KYAScripting.m
//  KeepingYouAwake
//

#import "KYAScripting.h"
#import <KYAApplicationSupport/KYAApplicationSupport.h>
#import <KYACommon/KYACommon.h>

#pragma mark - URL-scheme bridge

static void KYAScriptingPostURL(NSString *url)
{
    NSURL *target = [NSURL URLWithString:url];
    if(target == nil) { return; }
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
    if(seconds <= 0)
    {
        KYAScriptingPostURL(@"keepingyouawake:///activate");
    }
    else
    {
        KYAScriptingPostURL([NSString stringWithFormat:@"keepingyouawake:///activate?seconds=%ld", (long)seconds]);
    }
    return @YES;
}
@end

@implementation KYADeactivateScriptCommand
- (id)performDefaultImplementation
{
    BOOL wasActive = KYAScriptingProxy.sharedProxy.isActive;
    KYAScriptingPostURL(@"keepingyouawake:///deactivate");
    return @(wasActive);
}
@end

@implementation KYAToggleScriptCommand
- (id)performDefaultImplementation
{
    BOOL wasActive = KYAScriptingProxy.sharedProxy.isActive;
    KYAScriptingPostURL(@"keepingyouawake:///toggle");
    return @(!wasActive);
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
