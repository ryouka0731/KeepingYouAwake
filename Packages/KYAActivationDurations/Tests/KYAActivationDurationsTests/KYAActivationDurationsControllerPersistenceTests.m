//
//  KYAActivationDurationsControllerPersistenceTests.m
//  KYAActivationDurationsTests
//
//  Created by Claude on 13.05.26.
//

#import <XCTest/XCTest.h>
#import <KYACommon/KYACommon.h>
#import <KYAActivationDurations/KYAActivationDurations.h>

static NSString * const KYATestSuiteName = @"info.marcel-dierkes.KeepingYouAwake.ActivationDurationsControllerPersistenceTests";

@interface KYAActivationDurationsControllerPersistenceTests : XCTestCase
@property (nonatomic) NSUserDefaults *userDefaults;
@end

@implementation KYAActivationDurationsControllerPersistenceTests

- (void)setUp
{
    [super setUp];

    self.userDefaults = [[NSUserDefaults alloc] initWithSuiteName:KYATestSuiteName];
    [self.userDefaults removePersistentDomainForName:KYATestSuiteName];
}

- (void)tearDown
{
    [self.userDefaults removePersistentDomainForName:KYATestSuiteName];
    self.userDefaults = nil;

    [super tearDown];
}

- (KYAActivationDurationsController *)makeController
{
    return [[KYAActivationDurationsController alloc] initWithUserDefaults:self.userDefaults];
}

#pragma mark - Fresh state

- (void)testFreshControllerExposesDefaultsPlusIndefinite
{
    Auto controller = [self makeController];

    Auto expected = [NSMutableArray<KYAActivationDuration *>
                     arrayWithObject:KYAActivationDuration.indefiniteActivationDuration];
    [expected addObjectsFromArray:KYAActivationDuration.defaultActivationDurations];
    XCTAssertEqualObjects(controller.activationDurations, expected);

    // Indefinite is always at index 0 (sorted ascending by seconds).
    XCTAssertEqual(controller.activationDurations.firstObject.seconds, KYAActivationDurationIndefinite);
}

#pragma mark - Persistence round-trips

- (void)testAddedDurationSurvivesAcrossControllerInstances
{
    Auto controller = [self makeController];
    Auto added = [[KYAActivationDuration alloc] initWithSeconds:1234.0];
    XCTAssertTrue([controller addActivationDuration:added]);

    Auto reloaded = [self makeController];
    XCTAssertTrue([reloaded.activationDurations containsObject:added]);
}

- (void)testRemovedDurationStaysRemovedAfterReload
{
    Auto controller = [self makeController];
    Auto victim = controller.activationDurations[1];
    XCTAssertTrue([controller removeActivationDuration:victim]);

    Auto reloaded = [self makeController];
    XCTAssertFalse([reloaded.activationDurations containsObject:victim]);
}

- (void)testDefaultDurationPersistsAcrossReload
{
    Auto controller = [self makeController];
    Auto newDefault = controller.activationDurations[2];
    controller.defaultActivationDuration = newDefault;

    Auto reloaded = [self makeController];
    XCTAssertEqualObjects(reloaded.defaultActivationDuration, newDefault);
}

- (void)testRemovingTheDefaultDurationResetsItToIndefinite
{
    Auto controller = [self makeController];
    Auto chosen = controller.activationDurations[3];
    controller.defaultActivationDuration = chosen;
    XCTAssertEqualObjects(controller.defaultActivationDuration, chosen);

    XCTAssertTrue([controller removeActivationDuration:chosen]);
    XCTAssertEqualObjects(controller.defaultActivationDuration, KYAActivationDuration.indefiniteActivationDuration);
}

#pragma mark - canRemoveActivationDurationAtIndex:

- (void)testIndefiniteDurationCannotBeRemoved
{
    Auto controller = [self makeController];
    XCTAssertFalse([controller canRemoveActivationDurationAtIndex:0]);
    XCTAssertFalse([controller removeActivationDurationAtIndex:0]);
}

- (void)testFiniteDurationsCanBeRemoved
{
    Auto controller = [self makeController];
    XCTAssertTrue([controller canRemoveActivationDurationAtIndex:1]);
}

- (void)testOutOfBoundsIndexCannotBeRemoved
{
    Auto controller = [self makeController];
    XCTAssertFalse([controller canRemoveActivationDurationAtIndex:NSNotFound]);
    XCTAssertFalse([controller canRemoveActivationDurationAtIndex:controller.activationDurations.count]);
    XCTAssertFalse([controller removeActivationDurationAtIndex:9999]);
}

#pragma mark - Reset

- (void)testResetRestoresDefaultsAndIndefiniteDefaultDuration
{
    Auto controller = [self makeController];
    // Add a custom duration and mark it as the default so that reset must
    // both rebuild the durations array AND fall back to the indefinite
    // sentinel for the default (since the custom duration disappears).
    Auto custom = [[KYAActivationDuration alloc] initWithSeconds:777.0];
    [controller addActivationDuration:custom];
    controller.defaultActivationDuration = custom;
    XCTAssertEqualObjects(controller.defaultActivationDuration, custom);

    [controller resetActivationDurations];

    Auto expected = [NSMutableArray<KYAActivationDuration *>
                     arrayWithObject:KYAActivationDuration.indefiniteActivationDuration];
    [expected addObjectsFromArray:KYAActivationDuration.defaultActivationDurations];
    XCTAssertEqualObjects(controller.activationDurations, expected);

    // Reset must also restore the default duration to the indefinite sentinel,
    // matching the test method's name.
    XCTAssertEqualObjects(controller.defaultActivationDuration,
                          KYAActivationDuration.indefiniteActivationDuration);
}

@end
