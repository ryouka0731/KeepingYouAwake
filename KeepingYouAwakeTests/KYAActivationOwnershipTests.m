//
//  KYAActivationOwnershipTests.m
//  KeepingYouAwakeTests
//
//  Issue #85 acceptance criterion: "Cover
//  `terminateTimerIfOwnedBySource:` against each source enum value."
//
//  We can't headlessly instantiate `KYAAppController` (NSStatusItem,
//  asset-catalog images, distributed-notification observers, OS-level
//  monitors), so the source-aware ownership invariant lives in a small
//  testable value object — `KYAActivationOwnership`. The controller
//  delegates to it; these tests exercise the invariant directly.
//
//  Invariant under test (paraphrased from the issue body): a feature
//  trigger never deactivates a user-initiated session. Encoded by
//  `-terminateIfOwnedBySource:`: termination only happens when the
//  caller's source matches the recorded session source.
//

#import <XCTest/XCTest.h>
#import "KYAActivationSource.h"
#import "KYAActivationOwnership.h"

@interface KYAActivationOwnershipTests : XCTestCase
@property (nonatomic) KYAActivationOwnership *ownership;
@end

@implementation KYAActivationOwnershipTests

- (void)setUp
{
    [super setUp];
    self.ownership = [[KYAActivationOwnership alloc] init];
}

- (void)tearDown
{
    self.ownership = nil;
    [super tearDown];
}

#pragma mark - Fresh state

- (void)testFreshOwnershipIsInactive
{
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testStartWithSourceActivates
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

#pragma mark - Invariant: feature triggers can't end a User session
//
// AC for issue #85: one method per non-User KYAActivationSource value,
// each proving that calling -terminateIfOwnedBySource:<X> while the
// session is User-owned is a no-op (returns NO, session still active).

- (void)testTerminateIfOwnedBySourceWatchedAppNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceWatchedApp]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

- (void)testTerminateIfOwnedBySourceWatchedSSIDNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceWatchedSSID]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

- (void)testTerminateIfOwnedBySourceACPowerNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceACPower]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

- (void)testTerminateIfOwnedBySourceExternalDisplayNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceExternalDisplay]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

- (void)testTerminateIfOwnedBySourceScheduleNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceSchedule]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

- (void)testTerminateIfOwnedBySourceDownloadNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceDownload]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

- (void)testTerminateIfOwnedBySourceAudioOutputNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceAudioOutput]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

- (void)testTerminateIfOwnedBySourceCPULoadNoOpsWhenSessionIsUserOwned
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceCPULoad]);
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceUser);
}

#pragma mark - Each source can end its own session
//
// AC for issue #85: one method per KYAActivationSource value, each
// proving that calling -terminateIfOwnedBySource:<X> when the session
// is X-owned ends it cleanly (returns YES, session inactive).

- (void)testTerminateIfOwnedBySourceUserEndsUserSession
{
    [self.ownership startWithSource:KYAActivationSourceUser];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceUser]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceWatchedAppEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceWatchedApp];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceWatchedApp]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceWatchedSSIDEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceWatchedSSID];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceWatchedSSID]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceACPowerEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceACPower];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceACPower]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceExternalDisplayEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceExternalDisplay];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceExternalDisplay]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceScheduleEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceSchedule];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceSchedule]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceDownloadEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceDownload];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceDownload]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceAudioOutputEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceAudioOutput];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceAudioOutput]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateIfOwnedBySourceCPULoadEndsItsOwnSession
{
    [self.ownership startWithSource:KYAActivationSourceCPULoad];
    XCTAssertTrue([self.ownership terminateIfOwnedBySource:KYAActivationSourceCPULoad]);
    XCTAssertFalse(self.ownership.isActive);
}

#pragma mark - Edge cases

- (void)testTerminateIfOwnedBySourceOnFreshObjectReturnsNo
{
    // Defensive: the method must not crash or lie about success when
    // no session has been started. This pins down the `!active` branch.
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceUser]);
    XCTAssertFalse([self.ownership terminateIfOwnedBySource:KYAActivationSourceWatchedApp]);
    XCTAssertFalse(self.ownership.isActive);
}

- (void)testTerminateAlwaysEndsRegardlessOfSource
{
    // The user-initiated path (`-terminate`) is unconditional. Verified
    // here for every declared source: starting with X and then calling
    // -terminate must leave the object inactive.
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
    for(NSNumber *boxed in sources)
    {
        KYAActivationSource src = (KYAActivationSource)boxed.integerValue;
        KYAActivationOwnership *o = [[KYAActivationOwnership alloc] init];
        [o startWithSource:src];
        XCTAssertTrue(o.isActive, @"start did not activate for source %ld", (long)src);
        [o terminate];
        XCTAssertFalse(o.isActive, @"terminate did not deactivate for source %ld", (long)src);
    }
}

- (void)testStartWhileActiveReplacesSource
{
    // Matches the pre-extraction behavior in KYAAppController:
    // -activateTimerWithTimeInterval:source: unconditionally writes
    // self.activationSource = source on every call, so a feature
    // trigger calling activate while a User session is running takes
    // over the source. This is intentional — the running session is
    // already "live", we're just relabeling who owns it. The matching
    // -terminateIfOwnedBySource: invariant still holds because the new
    // owner gets to end its own session.
    [self.ownership startWithSource:KYAActivationSourceUser];
    [self.ownership startWithSource:KYAActivationSourceSchedule];
    XCTAssertTrue(self.ownership.isActive);
    XCTAssertEqual(self.ownership.source, KYAActivationSourceSchedule);
}

@end
