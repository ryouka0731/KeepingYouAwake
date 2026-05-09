//
//  KYADownloadActivityMonitor.m
//  KYAApplicationSupport
//

#import <KYAApplicationSupport/KYADownloadActivityMonitor.h>
#import <KYACommon/KYACommon.h>

@interface KYADownloadActivityMonitor ()
@property (copy, nonatomic) NSArray<NSString *> *expandedDirectories;
@property (nonatomic, nullable) NSTimer *tickTimer;
@property (nonatomic, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, readwrite) BOOL hasInProgressDownload;
@end

@implementation KYADownloadActivityMonitor

+ (NSArray<NSString *> *)defaultInProgressSuffixes
{
    static NSArray<NSString *> *suffixes;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        suffixes = @[@".crdownload", @".part", @".download", @".partial"];
    });
    return suffixes;
}

- (instancetype)init
{
    self = [super init];
    if(self) { _expandedDirectories = @[]; }
    return self;
}

- (void)dealloc
{
    [_tickTimer invalidate];
}

- (void)setDirectories:(NSArray<NSString *> *)directories
{
    NSMutableArray<NSString *> *expanded = [NSMutableArray array];
    for(NSString *path in directories)
    {
        if(![path isKindOfClass:NSString.class] || path.length == 0) { continue; }
        [expanded addObject:[path stringByExpandingTildeInPath]];
    }
    self.expandedDirectories = [expanded copy];

    if(expanded.count == 0)
    {
        // Match the documented "nil/empty effectively disables the
        // monitor" contract — stop the 10s timer so we don't keep
        // re-scanning an empty list, and surface the transition to
        // 'no downloads' if we were active.
        if(self.running && self.hasInProgressDownload)
        {
            self.hasInProgressDownload = NO;
            Auto delegate = self.delegate;
            if([delegate respondsToSelector:@selector(downloadActivityMonitorDidFinishDownloads:)])
            {
                [delegate downloadActivityMonitorDidFinishDownloads:self];
            }
        }
        [self stop];
        return;
    }

    if(self.running) { [self scanNow]; }
}

- (void)start
{
    if(self.running) { return; }
    self.running = YES;
    self.hasInProgressDownload = NO;

    [self scanNow];

    AutoWeak weakSelf = self;
    Auto timer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull t) {
        [weakSelf scanNow];
    }];
    timer.tolerance = 1.0;
    self.tickTimer = timer;
}

- (void)stop
{
    [self.tickTimer invalidate];
    self.tickTimer = nil;
    self.running = NO;
    self.hasInProgressDownload = NO;
}

- (void)scanNow
{
    BOOL found = NO;
    Auto suffixes = self.class.defaultInProgressSuffixes;
    Auto fileManager = NSFileManager.defaultManager;

    for(NSString *dir in self.expandedDirectories)
    {
        NSError *error = nil;
        NSArray<NSString *> *contents = [fileManager contentsOfDirectoryAtPath:dir error:&error];
        if(contents == nil) { continue; }
        for(NSString *name in contents)
        {
            for(NSString *suffix in suffixes)
            {
                if([name hasSuffix:suffix]) { found = YES; break; }
            }
            if(found) { break; }
        }
        if(found) { break; }
    }

    if(found == self.hasInProgressDownload) { return; }
    self.hasInProgressDownload = found;

    Auto delegate = self.delegate;
    if(found)
    {
        if([delegate respondsToSelector:@selector(downloadActivityMonitorDidStartDownloads:)])
        {
            [delegate downloadActivityMonitorDidStartDownloads:self];
        }
    }
    else
    {
        if([delegate respondsToSelector:@selector(downloadActivityMonitorDidFinishDownloads:)])
        {
            [delegate downloadActivityMonitorDidFinishDownloads:self];
        }
    }
}

@end
