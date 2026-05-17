//
//  KYAWatchedApplicationsTests.m
//  KeepingYouAwakeTests
//
//  Issue #85 acceptance criterion: cover the watched-app multi-bundle
//  membership logic (`-isWatchedBundleIdentifier:`).
//
//  These tests pin down the contract of
//  `KYAWatchedBundleIdentifiers_Contains()` — the pure helper extracted
//  from `KYAAppController -isWatchedBundleIdentifier:`. The helper takes
//  a watched list and a candidate bundle identifier and returns whether
//  the candidate matches any entry, case-insensitively.
//
//  We deliberately do NOT instantiate `KYAAppController` here:
//  `KYAAppController`'s initializer wires up `NSStatusItem`,
//  asset-catalog images, defaults observers, and OS-level monitors that
//  are not headless-friendly. Testing the pure membership helper in
//  isolation is the slice that fits in this PR.
//

#import <XCTest/XCTest.h>
#import "KYAWatchedApplications.h"

@interface KYAWatchedApplicationsTests : XCTestCase
@end

@implementation KYAWatchedApplicationsTests

#pragma mark - Degenerate inputs

- (void)testReturnsNOForEmptyArray
{
    // Both nil and empty array should return NO regardless of lookup.
    XCTAssertFalse(KYAWatchedBundleIdentifiers_Contains(nil, @"com.apple.Safari"));
    XCTAssertFalse(KYAWatchedBundleIdentifiers_Contains(@[], @"com.apple.Safari"));
}

- (void)testReturnsNOForNilLookup
{
    XCTAssertFalse(KYAWatchedBundleIdentifiers_Contains(@[@"com.apple.Safari"], nil));
}

- (void)testReturnsNOForEmptyLookup
{
    // Production code uses `bundleIdentifier.length == 0` as the early-out,
    // so `@""` short-circuits to NO even if the array contains `@""`.
    XCTAssertFalse(KYAWatchedBundleIdentifiers_Contains(@[@"com.apple.Safari"], @""));
    XCTAssertFalse(KYAWatchedBundleIdentifiers_Contains(@[@""], @""));
}

#pragma mark - Membership

- (void)testReturnsYESForExactMatch
{
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(@[@"com.apple.Safari"],
                                                       @"com.apple.Safari"));
}

- (void)testReturnsNOForNonMember
{
    XCTAssertFalse(KYAWatchedBundleIdentifiers_Contains(@[@"com.apple.Safari"],
                                                        @"com.apple.Mail"));
}

- (void)testMultipleEntriesAllChecked
{
    // The candidate is in the last slot — confirms the loop visits every
    // entry rather than short-circuiting after the first comparison.
    NSArray<NSString *> *watched = @[@"com.a", @"com.b", @"com.c"];
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(watched, @"com.c"));
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(watched, @"com.a"));
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(watched, @"com.b"));
    XCTAssertFalse(KYAWatchedBundleIdentifiers_Contains(watched, @"com.d"));
}

#pragma mark - Case sensitivity (production = case-insensitive)

/// Production uses `-caseInsensitiveCompare:`, so a watched entry
/// `com.apple.Safari` matches a candidate `com.apple.SAFARI` (and
/// every other case variant). This is intentional: bundle identifiers
/// are conventionally lowercase, but values entered through the
/// Watched Applications settings pane may carry mixed case.
- (void)testCaseSensitivityMatchesProduction
{
    NSArray<NSString *> *watched = @[@"com.apple.Safari"];
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(watched, @"com.apple.SAFARI"));
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(watched, @"com.apple.safari"));
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(watched, @"COM.APPLE.SAFARI"));
    XCTAssertTrue(KYAWatchedBundleIdentifiers_Contains(watched, @"com.apple.Safari"));
}

@end
