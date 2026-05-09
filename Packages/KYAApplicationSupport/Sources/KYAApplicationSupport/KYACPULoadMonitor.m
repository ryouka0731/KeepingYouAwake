//
//  KYACPULoadMonitor.m
//  KYAApplicationSupport
//

#import <KYAApplicationSupport/KYACPULoadMonitor.h>
#import <KYACommon/KYACommon.h>
#import <mach/mach.h>
#import <mach/host_info.h>

@interface KYACPULoadMonitor ()
@property (nonatomic, nullable) NSTimer *tickTimer;
@property (nonatomic, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, readwrite) double currentBusyPercent;
@property (nonatomic, readwrite) BOOL aboveThreshold;
/// Tick counters from the previous sample.
@property (nonatomic) natural_t lastUserTicks;
@property (nonatomic) natural_t lastSystemTicks;
@property (nonatomic) natural_t lastIdleTicks;
@property (nonatomic) natural_t lastNiceTicks;
@property (nonatomic) BOOL hasPriorSample;
/// How long the latest contiguous samples have been on each side.
@property (nonatomic) NSTimeInterval contiguousAboveSeconds;
@property (nonatomic) NSTimeInterval contiguousBelowSeconds;
@end

@implementation KYACPULoadMonitor

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _thresholdPercent = 50.0;
        _samplingInterval = 5.0;
        _dwell = 30.0;
        _currentBusyPercent = NAN;
    }
    return self;
}

- (void)dealloc
{
    [_tickTimer invalidate];
}

- (void)start
{
    if(self.running) { return; }
    self.running = YES;
    self.hasPriorSample = NO;
    self.contiguousAboveSeconds = 0;
    self.contiguousBelowSeconds = 0;

    [self sampleOnce];

    Auto timer = [NSTimer scheduledTimerWithTimeInterval:self.samplingInterval
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull t) {
        [self sampleOnce];
    }];
    timer.tolerance = MAX(0.5, self.samplingInterval * 0.1);
    self.tickTimer = timer;
}

- (void)stop
{
    [self.tickTimer invalidate];
    self.tickTimer = nil;
    self.running = NO;
    self.hasPriorSample = NO;
    self.aboveThreshold = NO;
    self.contiguousAboveSeconds = 0;
    self.contiguousBelowSeconds = 0;
    self.currentBusyPercent = NAN;
}

#pragma mark - Sampling

- (void)sampleOnce
{
    host_cpu_load_info_data_t cpuinfo;
    mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
    kern_return_t status = host_statistics(mach_host_self(),
                                           HOST_CPU_LOAD_INFO,
                                           (host_info_t)&cpuinfo,
                                           &count);
    if(status != KERN_SUCCESS) { return; }

    natural_t user = cpuinfo.cpu_ticks[CPU_STATE_USER];
    natural_t system = cpuinfo.cpu_ticks[CPU_STATE_SYSTEM];
    natural_t idle = cpuinfo.cpu_ticks[CPU_STATE_IDLE];
    natural_t nice = cpuinfo.cpu_ticks[CPU_STATE_NICE];

    if(!self.hasPriorSample)
    {
        self.lastUserTicks = user;
        self.lastSystemTicks = system;
        self.lastIdleTicks = idle;
        self.lastNiceTicks = nice;
        self.hasPriorSample = YES;
        return;
    }

    natural_t dUser = user - self.lastUserTicks;
    natural_t dSystem = system - self.lastSystemTicks;
    natural_t dIdle = idle - self.lastIdleTicks;
    natural_t dNice = nice - self.lastNiceTicks;
    natural_t totalDelta = dUser + dSystem + dIdle + dNice;

    self.lastUserTicks = user;
    self.lastSystemTicks = system;
    self.lastIdleTicks = idle;
    self.lastNiceTicks = nice;

    if(totalDelta == 0) { return; }
    double busy = 100.0 * (double)(dUser + dSystem + dNice) / (double)totalDelta;
    self.currentBusyPercent = busy;

    BOOL nowAbove = (busy > self.thresholdPercent);
    if(nowAbove)
    {
        self.contiguousAboveSeconds += self.samplingInterval;
        self.contiguousBelowSeconds = 0;
    }
    else
    {
        self.contiguousBelowSeconds += self.samplingInterval;
        self.contiguousAboveSeconds = 0;
    }

    Auto delegate = self.delegate;
    if(!self.aboveThreshold && self.contiguousAboveSeconds >= self.dwell)
    {
        self.aboveThreshold = YES;
        if([delegate respondsToSelector:@selector(cpuLoadMonitorDidCrossAboveThreshold:)])
        {
            [delegate cpuLoadMonitorDidCrossAboveThreshold:self];
        }
    }
    else if(self.aboveThreshold && self.contiguousBelowSeconds >= self.dwell)
    {
        self.aboveThreshold = NO;
        if([delegate respondsToSelector:@selector(cpuLoadMonitorDidFallBelowThreshold:)])
        {
            [delegate cpuLoadMonitorDidFallBelowThreshold:self];
        }
    }
}

@end
