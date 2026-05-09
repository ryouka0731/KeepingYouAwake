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
    [NSWorkspace.sharedWorkspace openURL:target];
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

@implementation KYAScriptingProxy

+ (instancetype)sharedProxy
{
    static dispatch_once_t once;
    static KYAScriptingProxy *shared;
    dispatch_once(&once, ^{ shared = [self new]; });
    return shared;
}

- (nullable KYAActivityLogEntry *)mostRecentOpenEntry
{
    Auto entries = [KYAActivityLogger.sharedLogger recentEntriesWithLimit:50];
    // recentEntriesWithLimit: returns newest-first.
    for(KYAActivityLogEntry *entry in entries)
    {
        if(entry.endedAt == nil) { return entry; }
    }
    return nil;
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
    return (NSInteger)remaining;
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
