//
//  KYADriveAliveTimer.m
//  KeepingYouAwake
//

#import "KYADriveAliveTimer.h"
#import <KYACommon/KYACommon.h>

@interface KYADriveAliveTimer ()
@property (nonatomic, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, nullable) dispatch_source_t timer;
@property (nonatomic, copy, readonly) NSURL *pingFileURL;
@property (nonatomic) os_log_t log;
@end

@implementation KYADriveAliveTimer
@synthesize pingFileURL = _pingFileURL;

- (instancetype)initWithInterval:(NSTimeInterval)interval
{
    self = [super init];
    if(self)
    {
        _interval = interval > 0 ? interval : 30.0;
        _log = KYALogCreateWithCategory("DriveAlive");
    }
    return self;
}

- (void)dealloc
{
    [self stop];
}

- (NSURL *)pingFileURL
{
    if(_pingFileURL == nil)
    {
        Auto fileName = [NSString stringWithFormat:@"info.marcel-dierkes.KeepingYouAwake.drive-alive.%d",
                         NSProcessInfo.processInfo.processIdentifier];
        _pingFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]
                                  isDirectory:NO];
    }
    return _pingFileURL;
}

- (void)start
{
    if(self.running) { return; }

    Auto queue = dispatch_queue_create("info.marcel-dierkes.KeepingYouAwake.drive-alive",
                                        DISPATCH_QUEUE_SERIAL);
    Auto source = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    uint64_t intervalNs = (uint64_t)(self.interval * NSEC_PER_SEC);
    // Fire immediately so a drive that's already near its spin-down
    // threshold gets touched before it stops; subsequent fires use
    // a loose 10% tolerance — exact firing isn't important.
    dispatch_source_set_timer(source,
                              DISPATCH_TIME_NOW,
                              intervalNs,
                              intervalNs / 10);

    AutoWeak weakSelf = self;
    dispatch_source_set_event_handler(source, ^{
        [weakSelf touchPingFile];
    });
    dispatch_resume(source);

    self.timer = source;
    self.running = YES;
    os_log(self.log, "%{public}@ started, interval=%.1fs, file=%{public}@", self, self.interval, self.pingFileURL.path);
}

- (void)stop
{
    if(!self.running) { return; }

    Auto source = self.timer;
    Auto pingURL = self.pingFileURL;
    Auto log = self.log;

    // `dispatch_source_cancel` is asynchronous — an in-flight timer
    // event can still execute and rewrite the ping file. Defer the
    // removal to the cancel handler, which runs after every pending
    // event has finished, so we never race a write against a delete.
    dispatch_source_set_cancel_handler(source, ^{
        NSError *removalError = nil;
        [NSFileManager.defaultManager removeItemAtURL:pingURL error:&removalError];
        if(removalError != nil && removalError.code != NSFileNoSuchFileError)
        {
            os_log_error(log, "drive-alive stop: failed to remove ping file: %{public}@", removalError);
        }
    });
    dispatch_source_cancel(source);

    self.timer = nil;
    self.running = NO;
    os_log(self.log, "%{public}@ stopped", self);
}

- (void)touchPingFile
{
    Auto data = [[NSString stringWithFormat:@"keepingyouawake %f\n",
                  NSDate.date.timeIntervalSince1970] dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    if(![data writeToURL:self.pingFileURL options:NSDataWritingAtomic error:&error])
    {
        os_log_error(self.log, "%{public}@ ping write failed: %{public}@", self, error);
    }
}

@end
