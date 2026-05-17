//
//  KYAWatchedApplications.h
//  KeepingYouAwake
//
//  Extracted from KYAAppController.m to allow unit testing of the
//  watched-application multi-bundle membership predicate without
//  depending on KYAAppController's AppKit / NSStatusItem-bound
//  initialization or on `NSUserDefaults`. The pure helper takes the
//  watched list and a candidate bundle identifier; the caller is
//  responsible for sourcing the watched list (production reads
//  `NSUserDefaults.standardUserDefaults.kya_watchedApplicationBundleIdentifiers`).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Returns `YES` if `bundleIdentifier` matches any entry in
/// `watchedIdentifiers`, case-**insensitively** (via
/// `-caseInsensitiveCompare:`). Returns `NO` when:
///
///   * `watchedIdentifiers` is `nil` or empty, or
///   * `bundleIdentifier` is `nil` or empty (`length == 0`), or
///   * no entry compares equal.
///
/// Matches the production behavior previously inlined in
/// `KYAAppController -isWatchedBundleIdentifier:`: bundle identifiers
/// are conventionally lowercase but user-entered values in the
/// Watched Applications settings pane may carry mixed case, so the
/// comparison is intentionally case-insensitive. The helper does NOT
/// trim whitespace — neither did the pre-extraction implementation.
FOUNDATION_EXPORT BOOL KYAWatchedBundleIdentifiers_Contains(
    NSArray<NSString *> * _Nullable watchedIdentifiers,
    NSString * _Nullable bundleIdentifier);

NS_ASSUME_NONNULL_END
