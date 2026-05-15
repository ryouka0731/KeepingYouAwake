//
//  KYAActivationDurationEdgeCaseTests.m
//  KYAActivationDurationsTests
//
//  Created by Claude on 13.05.26.
//

#import <XCTest/XCTest.h>
#import <KYACommon/KYACommon.h>
#import <KYAActivationDurations/KYAActivationDurations.h>

@interface KYAActivationDurationEdgeCaseTests : XCTestCase
@end

@implementation KYAActivationDurationEdgeCaseTests

#pragma mark - initWithHours:minutes:seconds: rejection

- (void)testComponentsInitializerRejectsMinutesGreaterThanAnHour
{
    XCTAssertNil([[KYAActivationDuration alloc] initWithHours:0 minutes:61 seconds:0]);
}

- (void)testComponentsInitializerRejectsSecondsGreaterThanAMinute
{
    XCTAssertNil([[KYAActivationDuration alloc] initWithHours:0 minutes:0 seconds:61]);
}

- (void)testComponentsInitializerRejectsZeroDuration
{
    XCTAssertNil([[KYAActivationDuration alloc] initWithHours:0 minutes:0 seconds:0]);
}

- (void)testComponentsInitializerAcceptsBoundaryValues
{
    // 60 minutes and 60 seconds are still allowed (the guard is "> 1h" / "> 1min").
    Auto duration = [[KYAActivationDuration alloc] initWithHours:1 minutes:60 seconds:60];
    XCTAssertNotNil(duration);
    XCTAssertEqual(duration.seconds, 3600.0 + 3600.0 + 60.0);
}

- (void)testComponentsInitializerWithOnlyHours
{
    Auto duration = [[KYAActivationDuration alloc] initWithHours:2 minutes:0 seconds:0];
    XCTAssertNotNil(duration);
    XCTAssertEqual(duration.seconds, 7200.0);
}

#pragma mark - Hashable / Equatable

- (void)testEqualDurationsShareHash
{
    Auto a = [[KYAActivationDuration alloc] initWithSeconds:1800.0];
    Auto b = [[KYAActivationDuration alloc] initWithSeconds:1800.0];
    XCTAssertEqual(a.hash, b.hash);
    XCTAssertEqualObjects(a, b);

    Auto set = [NSSet setWithObjects:a, b, nil];
    XCTAssertEqual(set.count, 1);
}

- (void)testIsEqualRejectsNilAndForeignTypes
{
    Auto duration = [[KYAActivationDuration alloc] initWithSeconds:300.0];
    XCTAssertFalse([duration isEqual:nil]);
    XCTAssertFalse([duration isEqual:@300]);
    XCTAssertFalse([duration isEqual:@"300"]);
    XCTAssertTrue([duration isEqual:duration]);
}

#pragma mark - NSSecureCoding

- (void)testSupportsSecureCoding
{
    XCTAssertTrue([KYAActivationDuration supportsSecureCoding]);
}

- (void)testSecureCodingRoundTripPreservesSeconds
{
    Auto original = [[KYAActivationDuration alloc] initWithSeconds:5400.0];
    NSError *error;
    Auto data = [NSKeyedArchiver archivedDataWithRootObject:original
                                      requiringSecureCoding:YES
                                                      error:&error];
    XCTAssertNotNil(data);
    XCTAssertNil(error);

    Auto decoded = (KYAActivationDuration *)[NSKeyedUnarchiver unarchivedObjectOfClass:[KYAActivationDuration class]
                                                                              fromData:data
                                                                                 error:&error];
    XCTAssertNil(error);
    XCTAssertEqual(decoded.seconds, original.seconds);
    XCTAssertEqualObjects(decoded, original);
}

#pragma mark - Description

- (void)testDescriptionMentionsSeconds
{
    Auto duration = [[KYAActivationDuration alloc] initWithSeconds:900.0];
    XCTAssertTrue([duration.description containsString:@"900"]);
}

@end
