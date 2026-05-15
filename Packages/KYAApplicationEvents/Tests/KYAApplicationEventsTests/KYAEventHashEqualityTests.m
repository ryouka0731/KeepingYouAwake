//
//  KYAEventHashEqualityTests.m
//  KYAApplicationEventsTests
//
//  Created by Claude on 13.05.26.
//

#import <XCTest/XCTest.h>
#import <KYACommon/KYACommon.h>
#import <KYAApplicationEvents/KYAApplicationEvents.h>

@interface KYAEventHashEqualityTests : XCTestCase
@end

@implementation KYAEventHashEqualityTests

- (void)testIsEqualToSelfAndIdenticalValues
{
    Auto event = [[KYAEvent alloc] initWithName:@"activate" arguments:@{ @"seconds": @"60" }];
    XCTAssertTrue([event isEqual:event]);
    Auto twin = [[KYAEvent alloc] initWithName:@"activate" arguments:@{ @"seconds": @"60" }];
    XCTAssertTrue([event isEqual:twin]);
    XCTAssertTrue([event isEqualToEvent:twin]);
}

- (void)testIsEqualRejectsNilAndForeignTypes
{
    Auto event = [[KYAEvent alloc] initWithName:@"activate" arguments:nil];
    XCTAssertFalse([event isEqual:nil]);
    XCTAssertFalse([event isEqual:@"activate"]);
    XCTAssertFalse([event isEqual:@42]);
}

- (void)testEqualEventsShareHash
{
    Auto event = [[KYAEvent alloc] initWithName:@"toggle" arguments:@{ @"a": @"1" }];
    Auto twin = [[KYAEvent alloc] initWithName:@"toggle" arguments:@{ @"a": @"1" }];
    XCTAssertEqual(event.hash, twin.hash);

    // Usable as a dictionary / set key.
    Auto set = [NSSet setWithObjects:event, twin, nil];
    XCTAssertEqual(set.count, 1);
}

- (void)testDifferentNameOrArgumentsAreNotEqual
{
    Auto base = [[KYAEvent alloc] initWithName:@"activate" arguments:@{ @"seconds": @"60" }];
    XCTAssertFalse([base isEqualToEvent:[[KYAEvent alloc] initWithName:@"deactivate"
                                                            arguments:@{ @"seconds": @"60" }]]);
    XCTAssertFalse([base isEqualToEvent:[[KYAEvent alloc] initWithName:@"activate"
                                                            arguments:@{ @"seconds": @"30" }]]);
}

- (void)testDescriptionMentionsNameAndArguments
{
    Auto event = [[KYAEvent alloc] initWithName:@"activate" arguments:@{ @"seconds": @"60" }];
    Auto description = event.description;
    XCTAssertTrue([description containsString:@"activate"]);
    XCTAssertTrue([description containsString:@"seconds"]);
}

@end
