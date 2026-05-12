//
//  KYASleepWakeTimerTests.m
//  KYASleepWakeTimerTests
//
//  Created by Claude on 13.05.26.
//

#import <XCTest/XCTest.h>
#import <KYACommon/KYACommon.h>
#import <KYASleepWakeTimer/KYASleepWakeTimer.h>

@interface KYASleepWakeTimerTestDelegate : NSObject <KYASleepWakeTimerDelegate>
@property (nonatomic) NSTimeInterval lastWillActivateInterval;
@property (nonatomic) BOOL didReceiveWillActivate;
@property (nonatomic, copy, nullable) void (^onDeactivate)(void);
@end

@implementation KYASleepWakeTimerTestDelegate

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _lastWillActivateInterval = -1.0;
    }
    return self;
}

- (void)sleepWakeTimer:(KYASleepWakeTimer *)sleepWakeTimer willActivateWithTimeInterval:(NSTimeInterval)timeInterval
{
    self.didReceiveWillActivate = YES;
    self.lastWillActivateInterval = timeInterval;
}

- (void)sleepWakeTimerDidDeactivate:(KYASleepWakeTimer *)sleepWakeTimer
{
    if(self.onDeactivate) { self.onDeactivate(); }
}

@end

#pragma mark -

@interface KYASleepWakeTimerTests : XCTestCase
@property (nonatomic) KYASleepWakeTimer *timer;
@end

@implementation KYASleepWakeTimerTests

- (void)setUp
{
    [super setUp];

    self.timer = [KYASleepWakeTimer new];
}

- (void)tearDown
{
    [self.timer invalidate];
    self.timer = nil;

    [super tearDown];
}

#pragma mark - Constant

- (void)testIndefiniteConstantIsZero
{
    XCTAssertEqual(KYASleepWakeTimeIntervalIndefinite, 0.0);
}

#pragma mark - Initial state

- (void)testFreshTimerIsNotScheduled
{
    Auto timer = self.timer;
    XCTAssertFalse(timer.isScheduled);
    XCTAssertNil(timer.fireDate);
    XCTAssertEqual(timer.scheduledTimeInterval, KYASleepWakeTimeIntervalIndefinite);
}

#pragma mark - Scheduling

- (void)testScheduleSetsFireDateAndIntervalForFiniteInterval
{
    Auto timer = self.timer;
    NSTimeInterval interval = 600.0;
    Auto before = NSDate.date;

    [timer scheduleWithTimeInterval:interval completion:nil];

    XCTAssertEqual(timer.scheduledTimeInterval, interval);
    XCTAssertNotNil(timer.fireDate);
    // The fire date should be roughly `interval` seconds out from now.
    NSTimeInterval delta = [timer.fireDate timeIntervalSinceDate:before];
    XCTAssertEqualWithAccuracy(delta, interval, 5.0);
}

- (void)testScheduleIndefiniteHasNilFireDate
{
    Auto timer = self.timer;

    [timer scheduleWithTimeInterval:KYASleepWakeTimeIntervalIndefinite completion:nil];

    XCTAssertNil(timer.fireDate);
    XCTAssertEqual(timer.scheduledTimeInterval, KYASleepWakeTimeIntervalIndefinite);
}

#pragma mark - Invalidation

- (void)testInvalidateClearsScheduledState
{
    Auto timer = self.timer;
    [timer scheduleWithTimeInterval:600.0 completion:nil];

    [timer invalidate];

    XCTAssertNil(timer.fireDate);
    XCTAssertEqual(timer.scheduledTimeInterval, KYASleepWakeTimeIntervalIndefinite);
    XCTAssertFalse(timer.isScheduled);
}

- (void)testDoubleInvalidateIsSafe
{
    Auto timer = self.timer;
    [timer scheduleWithTimeInterval:600.0 completion:nil];

    XCTAssertNoThrow([timer invalidate]);
    XCTAssertNoThrow([timer invalidate]);
    XCTAssertNoThrow([timer invalidate]);
    XCTAssertNil(timer.fireDate);
}

- (void)testInvalidateWithoutSchedulingIsSafe
{
    Auto timer = self.timer;
    XCTAssertNoThrow([timer invalidate]);
    XCTAssertFalse(timer.isScheduled);
}

#pragma mark - Completion block

- (void)testCompletionBlockReceivesCancelledOnInvalidate
{
    Auto timer = self.timer;
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];

    [timer scheduleWithTimeInterval:600.0 completion:^(BOOL cancelled) {
        XCTAssertTrue(cancelled);
        [expectation fulfill];
    }];
    [timer invalidate];

    [self waitForExpectations:@[expectation] timeout:5.0];
}

#pragma mark - Delegate

- (void)testDelegateReceivesWillActivateWithInterval
{
    Auto timer = self.timer;
    Auto delegate = [KYASleepWakeTimerTestDelegate new];
    timer.delegate = delegate;

    [timer scheduleWithTimeInterval:300.0 completion:nil];

    XCTAssertTrue(delegate.didReceiveWillActivate);
    XCTAssertEqual(delegate.lastWillActivateInterval, 300.0);
}

- (void)testDelegateReceivesDidDeactivateOnInvalidate
{
    Auto timer = self.timer;
    Auto delegate = [KYASleepWakeTimerTestDelegate new];
    timer.delegate = delegate;

    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    delegate.onDeactivate = ^{ [expectation fulfill]; };

    [timer scheduleWithTimeInterval:600.0 completion:nil];
    [timer invalidate];

    [self waitForExpectations:@[expectation] timeout:5.0];
}

@end
