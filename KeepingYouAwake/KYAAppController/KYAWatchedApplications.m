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
    // `for…in` over a nil/empty array is already a no-op, so no explicit
    // count check is needed. The `isKindOfClass:` guard defends against
    // plist-sourced malformation: `kya_watchedApplicationBundleIdentifiers`
    // ultimately reads from `NSUserDefaults`, and a user can
    // `defaults write -array` non-string values (`NSNumber`, `NSNull`,
    // `NSDictionary`, …) into the slot. Without this guard those values
    // would crash in `-caseInsensitiveCompare:` (`unrecognized selector`).
    for(NSString *candidate in watchedIdentifiers)
    {
        if(![candidate isKindOfClass:[NSString class]]) { continue; }
        if([bundleIdentifier caseInsensitiveCompare:candidate] == NSOrderedSame)
        {
            return YES;
        }
    }
    return NO;
}
