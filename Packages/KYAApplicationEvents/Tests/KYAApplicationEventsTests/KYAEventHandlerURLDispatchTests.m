//
//  KYAEventHandlerURLDispatchTests.m
//  KYAApplicationEventsTests
//
//  Created by Claude on 13.05.26.
//

#import <XCTest/XCTest.h>
#import <KYACommon/KYACommon.h>
#import <KYAApplicationEvents/KYAApplicationEvents.h>

@interface KYAEventHandlerURLDispatchTests : XCTestCase
@property (nonatomic) KYAEventHandler *eventHandler;
@end

@implementation KYAEventHandlerURLDispatchTests

- (void)setUp
{
    [super setUp];

    self.eventHandler = [KYAEventHandler new];
}

#pragma mark - Action dispatch

- (void)testActivateWithSecondsArgument
{
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        XCTAssertEqualObjects(event.name, @"activate");
        XCTAssertEqualObjects(event.arguments, (@{ @"seconds": @"60" }));
        [expectation fulfill];
    }];
    [self.eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///activate?seconds=60"]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
}

- (void)testDeactivateWithoutArguments
{
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.eventHandler registerActionNamed:@"deactivate" block:^(KYAEvent *event) {
        XCTAssertEqualObjects(event.name, @"deactivate");
        XCTAssertNil(event.arguments);
        [expectation fulfill];
    }];
    [self.eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///deactivate"]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
}

- (void)testToggleAction
{
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.eventHandler registerActionNamed:@"toggle" block:^(KYAEvent *event) {
        XCTAssertEqualObjects(event.name, @"toggle");
        [expectation fulfill];
    }];
    [self.eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///toggle"]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
}

- (void)testMultipleQueryArguments
{
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        XCTAssertEqualObjects(event.arguments, (@{ @"seconds": @"30", @"foo": @"bar" }));
        [expectation fulfill];
    }];
    [self.eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///activate?seconds=30&foo=bar"]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
}

- (void)testEmptyQueryValueFallsBackToEmptyString
{
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        XCTAssertEqualObjects(event.arguments, (@{ @"seconds": @"" }));
        [expectation fulfill];
    }];
    [self.eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///activate?seconds="]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
}

- (void)testValuelessQueryItemFallsBackToEmptyString
{
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [self.eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        XCTAssertEqualObjects(event.arguments, (@{ @"seconds": @"" }));
        [expectation fulfill];
    }];
    [self.eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///activate?seconds"]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
}

#pragma mark - Negative / malformed cases

- (void)testUnknownActionDoesNotInvokeRegisteredBlocks
{
    Auto eventHandler = self.eventHandler;
    [eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        XCTFail(@"The activate block must not be invoked for an unknown host.");
    }];
    [eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///doesNotExist"]];

    // The event queue is serial; once a subsequent known action drains, the
    // unknown one has already been processed without invoking any block.
    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [eventHandler registerActionNamed:@"deactivate" block:^(KYAEvent *event) {
        [expectation fulfill];
    }];
    [eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///deactivate"]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
}

- (void)testNilURLIsIgnored
{
    Auto eventHandler = self.eventHandler;
    [eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        XCTFail(@"No block should be invoked for a nil URL.");
    }];
    NSURL *nilURL = nil;
    XCTAssertNoThrow([eventHandler handleEventForURL:nilURL]);
}

- (void)testRemovedActionIsNoLongerInvoked
{
    Auto eventHandler = self.eventHandler;
    __block BOOL invoked = NO;
    [eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        invoked = YES;
    }];
    [eventHandler removeActionNamed:@"activate"];
    [eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///activate?seconds=10"]];

    Auto expectation = [self expectationWithDescription:NSStringFromSelector(_cmd)];
    [eventHandler registerActionNamed:@"deactivate" block:^(KYAEvent *event) {
        [expectation fulfill];
    }];
    [eventHandler handleEventForURL:[NSURL URLWithString:@"kya:///deactivate"]];
    [self waitForExpectations:@[expectation] timeout:5.0f];
    XCTAssertFalse(invoked);
}

@end
