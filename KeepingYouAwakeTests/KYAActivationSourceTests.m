//
//  KYAActivationSourceTests.m
//  KeepingYouAwakeTests
//
//  Goal-1 coverage for issue #85: source-aware invariant.
//
//  These tests pin down the contract of
//  `KYAActivityLogStringForSource()` — the production helper that turns
//  a `KYAActivationSource` activation reason into the corresponding
//  `KYAActivityLogSource*` string constant from `KYAActivityLogger.h`.
//  The acceptance criterion is at least one test per
//  `KYAActivationSource` enum value, so each case below covers exactly
//  one enumerator.
//
//  We deliberately do NOT instantiate KYAAppController here:
//  KYAAppController's initializer wires up `NSStatusItem`, asset-catalog
//  images, defaults observers, and OS-level monitors that are not
//  headless-friendly. Testing the pure mapping helper in isolation is
//  the slice that fits in this PR; broader KYAAppController test
//  coverage is tracked separately under issue #85 (goals 4 + 5).
//

#import <XCTest/XCTest.h>
#import <KYAApplicationSupport/KYAApplicationSupport.h>
#import "KYAActivationSource.h"

@interface KYAActivationSourceTests : XCTestCase
@end

@implementation KYAActivationSourceTests

#pragma mark - One test per KYAActivationSource enum value

- (void)testUserSourceMapsToUserLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceUser),
                          KYAActivityLogSourceUser);
}

- (void)testWatchedAppSourceMapsToWatchedAppLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceWatchedApp),
                          KYAActivityLogSourceWatchedApp);
}

- (void)testWatchedSSIDSourceMapsToWatchedSSIDLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceWatchedSSID),
                          KYAActivityLogSourceWatchedSSID);
}

- (void)testACPowerSourceMapsToACPowerLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceACPower),
                          KYAActivityLogSourceACPower);
}

- (void)testExternalDisplaySourceMapsToExternalDisplayLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceExternalDisplay),
                          KYAActivityLogSourceExternalDisplay);
}

- (void)testScheduleSourceMapsToScheduleLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceSchedule),
                          KYAActivityLogSourceSchedule);
}

- (void)testDownloadSourceMapsToDownloadLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceDownload),
                          KYAActivityLogSourceDownload);
}

- (void)testAudioOutputSourceMapsToAudioOutputLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceAudioOutput),
                          KYAActivityLogSourceAudioOutput);
}

- (void)testCPULoadSourceMapsToCPULoadLog
{
    XCTAssertEqualObjects(KYAActivityLogStringForSource(KYAActivationSourceCPULoad),
                          KYAActivityLogSourceCPULoad);
}

#pragma mark - Whole-domain invariants

/// Belt-and-suspenders: every declared enum value maps to a non-empty
/// string, and no two distinct enum values map to the same string
/// (the mapping is injective over the declared domain). If a future
/// `KYAActivationSource` case is added without a matching switch arm,
/// this test will fail because the new case falls through to the
/// `User` default and collides with `KYAActivationSourceUser`.
- (void)testAllDeclaredEnumValuesMapToDistinctNonEmptyStrings
{
    NSArray<NSNumber *> *sources = @[
        @(KYAActivationSourceUser),
        @(KYAActivationSourceWatchedApp),
        @(KYAActivationSourceWatchedSSID),
        @(KYAActivationSourceACPower),
        @(KYAActivationSourceExternalDisplay),
        @(KYAActivationSourceSchedule),
        @(KYAActivationSourceDownload),
        @(KYAActivationSourceAudioOutput),
        @(KYAActivationSourceCPULoad),
    ];
    NSMutableSet<NSString *> *seen = [NSMutableSet setWithCapacity:sources.count];
    for(NSNumber *boxed in sources)
    {
        KYAActivationSource src = (KYAActivationSource)boxed.integerValue;
        NSString *log = KYAActivityLogStringForSource(src);
        XCTAssertNotNil(log, @"source %ld mapped to nil", (long)src);
        XCTAssertGreaterThan(log.length, (NSUInteger)0,
                             @"source %ld mapped to empty string", (long)src);
        XCTAssertFalse([seen containsObject:log],
                       @"source %ld collides with an earlier mapping (%@)",
                       (long)src, log);
        [seen addObject:log];
    }
    XCTAssertEqual(seen.count, sources.count);
}

/// Out-of-band integer values cast to `KYAActivationSource` are a real
/// possibility — `terminateTimerIfOwnedBySource:` is invoked with the
/// raw NS_ENUM type from monitor callbacks. The documented behavior is
/// "fall back to User"; this test pins that down so a future refactor
/// can't silently change it to "return nil" or "trap".
- (void)testUnknownSourceFallsBackToUser
{
    KYAActivationSource bogus = (KYAActivationSource)999;
    XCTAssertEqualObjects(KYAActivityLogStringForSource(bogus),
                          KYAActivityLogSourceUser);
}

@end
