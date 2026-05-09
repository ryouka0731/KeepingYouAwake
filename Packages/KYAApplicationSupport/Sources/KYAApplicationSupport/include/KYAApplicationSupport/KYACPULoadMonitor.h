//
//  KYACPULoadMonitor.h
//  KYAApplicationSupport
//
//  Created for KeepingYouAwake-Amphetamine fork (issue #43).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KYACPULoadMonitorDelegate;

/// Polls system-wide CPU usage. Notifies its delegate on transitions
/// between "sustained above threshold" and "sustained below threshold".
///
/// Sampling is done via `host_statistics(HOST_CPU_LOAD_INFO)` every
/// `samplingInterval` (default 5 seconds). Each sample yields a busy
/// percentage by computing the delta of (user + system + nice) ticks
/// over the delta of total ticks since the previous sample. The first
/// sample after `start` produces no percentage and never fires.
///
/// To avoid flapping, the monitor uses a sustained-window: a
/// transition fires only after `dwell` seconds of consecutive samples
/// on the same side of the threshold. Default dwell: 30 seconds.
@interface KYACPULoadMonitor : NSObject

@property (weak, nonatomic, nullable) id<KYACPULoadMonitorDelegate> delegate;

@property (readonly, nonatomic, getter=isRunning) BOOL running;

/// Threshold in 0..100 (percent). Default 50.
@property (nonatomic) double thresholdPercent;

/// Sampling interval in seconds. Default 5.
@property (nonatomic) NSTimeInterval samplingInterval;

/// Dwell window in seconds before a transition fires. Default 30.
@property (nonatomic) NSTimeInterval dwell;

/// Latest computed busy percentage (0..100). NaN until at least 2
/// samples have been collected. Useful for diagnostics.
@property (readonly, nonatomic) double currentBusyPercent;

/// YES if the most recent transition was into the "above-threshold"
/// state. Exposed for tests.
@property (readonly, nonatomic) BOOL aboveThreshold;

- (void)start;
- (void)stop;

@end

@protocol KYACPULoadMonitorDelegate <NSObject>
@optional
- (void)cpuLoadMonitorDidCrossAboveThreshold:(KYACPULoadMonitor *)monitor;
- (void)cpuLoadMonitorDidFallBelowThreshold:(KYACPULoadMonitor *)monitor;
@end

NS_ASSUME_NONNULL_END
