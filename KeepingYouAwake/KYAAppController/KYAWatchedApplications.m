//
//  KYAWatchedApplications.m
//  KeepingYouAwake
//
//  Extracted from KYAAppController.m to allow unit testing of the
//  watched-application multi-bundle membership predicate without
//  depending on KYAAppController's AppKit / NSStatusItem-bound
//  initialization.
//

#import "KYAWatchedApplications.h"

BOOL KYAWatchedBundleIdentifiers_Contains(
    NSArray<NSString *> * _Nullable watchedIdentifiers,
    NSString * _Nullable bundleIdentifier)
{
    if(bundleIdentifier.length == 0) { return NO; }
    if(watchedIdentifiers.count == 0) { return NO; }
    for(NSString *candidate in watchedIdentifiers)
    {
        if([bundleIdentifier caseInsensitiveCompare:candidate] == NSOrderedSame)
        {
            return YES;
        }
    }
    return NO;
}
