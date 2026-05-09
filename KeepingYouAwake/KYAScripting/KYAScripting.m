//
//  KYAScripting.m
//  KeepingYouAwake
//

#import "KYAScripting.h"
#import <KYAApplicationSupport/KYAApplicationSupport.h>

#pragma mark - URL-scheme bridge

static void KYAScriptingPostURL(NSString *url)
{
    Auto components = [NSURLComponents new];
    Auto raw = [NSURL URLWithString:url];
    components.scheme = raw.scheme;
    components.host = raw.host;
    components.path = raw.path;
    components.query = raw.query;
    NSURL *target = components.URL ?: raw;
    [NSWorkspace.sharedWorkspace openURL:target];
}

#pragma mark - Commands

@implementation KYAActivateScriptCommand
- (id)performDefaultImplementation
{
    NSDictionary *args = self.evaluatedArguments;
    NSNumber *durationArg = args[@"Duration"];
    if(durationArg == nil)
    {
        // No `for` clause — direct property positional.
        durationArg = self.directParameter;
        if(![durationArg isKindOfClass:NSNumber.class]) { durationArg = nil; }
    }

    NSInteger seconds = durationArg.integerValue;
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

- (NSArray<KYAActivityLogEntry *> *)recentEntriesOrEmpty
{
    @try
    {
        return [KYAActivityLogger.sharedLogger recentEntriesWithLimit:50];
    }
    @catch(NSException *e)
    {
        return @[];
    }
}

- (nullable KYAActivityLogEntry *)mostRecentOpenEntry
{
    Auto entries = [self recentEntriesOrEmpty];
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

#pragma mark - Scripting glue

- (NSScriptObjectSpecifier *)objectSpecifier
{
    Auto desc = [NSApplication.sharedApplication classDescription];
    return [[NSPropertySpecifier alloc] initWithContainerClassDescription:(NSScriptClassDescription *)desc
                                                       containerSpecifier:nil
                                                                      key:@"sharedProxy"];
}

@end
