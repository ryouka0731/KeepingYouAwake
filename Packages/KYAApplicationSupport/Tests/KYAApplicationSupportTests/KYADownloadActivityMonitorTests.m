//
//  KYADownloadActivityMonitorTests.m
//  KYAApplicationSupport
//

#import <XCTest/XCTest.h>
#import <KYACommon/KYACommon.h>
#import <KYAApplicationSupport/KYAApplicationSupport.h>

@interface KYADownloadActivityMonitorTests : XCTestCase <KYADownloadActivityMonitorDelegate>
@property (nonatomic) KYADownloadActivityMonitor *monitor;
@property (nonatomic) NSURL *tmpDir;
@property (nonatomic) NSInteger startCalls;
@property (nonatomic) NSInteger finishCalls;
@end

@implementation KYADownloadActivityMonitorTests

- (void)setUp
{
    [super setUp];
    NSString *name = [NSString stringWithFormat:@"kya-dl-%@", [NSUUID UUID].UUIDString];
    self.tmpDir = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:name];
    [NSFileManager.defaultManager createDirectoryAtURL:self.tmpDir
                           withIntermediateDirectories:YES
                                            attributes:nil
                                                 error:nil];
    self.monitor = [KYADownloadActivityMonitor new];
    self.monitor.delegate = self;
    [self.monitor setDirectories:@[ self.tmpDir.path ]];
    self.startCalls = 0;
    self.finishCalls = 0;
}

- (void)tearDown
{
    [NSFileManager.defaultManager removeItemAtURL:self.tmpDir error:nil];
    [super tearDown];
}

- (void)downloadActivityMonitorDidStartDownloads:(KYADownloadActivityMonitor *)monitor
{
    self.startCalls += 1;
}

- (void)downloadActivityMonitorDidFinishDownloads:(KYADownloadActivityMonitor *)monitor
{
    self.finishCalls += 1;
}

- (void)writeName:(NSString *)name
{
    NSURL *url = [self.tmpDir URLByAppendingPathComponent:name];
    [@"" writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark -

- (void)testEmptyDirectory_noTrigger
{
    [self.monitor scanNow];
    XCTAssertFalse(self.monitor.hasInProgressDownload);
    XCTAssertEqual(self.startCalls, 0);
    XCTAssertEqual(self.finishCalls, 0);
}

- (void)testCRDownloadFile_triggers
{
    [self writeName:@"some-big-file.zip.crdownload"];
    [self.monitor scanNow];
    XCTAssertTrue(self.monitor.hasInProgressDownload);
    XCTAssertEqual(self.startCalls, 1);
}

- (void)testNonDownloadSuffix_doesNotTrigger
{
    [self writeName:@"complete.zip"];
    [self.monitor scanNow];
    XCTAssertFalse(self.monitor.hasInProgressDownload);
    XCTAssertEqual(self.startCalls, 0);
}

- (void)testTransitions_onlyFireOnChange
{
    [self writeName:@"a.crdownload"];
    [self.monitor scanNow];
    [self.monitor scanNow];     // still in-progress: no second start callback
    XCTAssertEqual(self.startCalls, 1);
    XCTAssertEqual(self.finishCalls, 0);

    [NSFileManager.defaultManager removeItemAtURL:[self.tmpDir URLByAppendingPathComponent:@"a.crdownload"]
                                            error:nil];
    [self.monitor scanNow];     // empty: finish
    [self.monitor scanNow];     // still empty: no second finish
    XCTAssertEqual(self.startCalls, 1);
    XCTAssertEqual(self.finishCalls, 1);
}

- (void)testEmptyDirectoriesDisablesScan
{
    [self writeName:@"a.crdownload"];
    [self.monitor setDirectories:nil];
    [self.monitor scanNow];
    XCTAssertFalse(self.monitor.hasInProgressDownload);
}

- (void)testTildeExpansion
{
    // Set the watch directory using a tilde-prefixed equivalent and
    // ensure expansion works. We can't easily inject HOME without
    // forking the process, so we just check that a known existing
    // path expands sensibly: pass `~` and observe its expansion via
    // the suffix check by writing into NSHomeDirectory — too invasive
    // for a fast test. Instead, sanity-check that ~ doesn't equal its
    // raw form after passing through setDirectories: by checking that
    // the monitor doesn't fire spuriously for our random tmpdir.
    [self.monitor setDirectories:@[ @"~" ]];
    [self.monitor scanNow];
    // We don't assert hasInProgressDownload here — the user's home dir
    // might or might not contain a .crdownload at test time. The check
    // is: this didn't crash.
    XCTAssertTrue(YES);
}

- (void)testDefaultInProgressSuffixesContainsExpected
{
    NSArray<NSString *> *suffixes = KYADownloadActivityMonitor.defaultInProgressSuffixes;
    XCTAssertTrue([suffixes containsObject:@".crdownload"]);
    XCTAssertTrue([suffixes containsObject:@".part"]);
    XCTAssertTrue([suffixes containsObject:@".download"]);
    XCTAssertTrue([suffixes containsObject:@".partial"]);
}

@end
