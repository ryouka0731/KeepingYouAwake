//
//  KYAAudioOutputMonitor.h
//  KYAApplicationSupport
//
//  Created for KeepingYouAwake-Amphetamine fork (issue #50).
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KYAAudioOutputMonitorDelegate;

/// Watches the system's default audio output device and notifies its
/// delegate on transitions between "external" (Bluetooth, USB,
/// AirPlay, HDMI, virtual, …) and "built-in".
///
/// The monitor uses Core Audio's property listener API on
/// `kAudioHardwarePropertyDefaultOutputDevice`. Plugging AirPods, an
/// external DAC, or routing audio to AirPlay all switch the default
/// output device — that's the signal we react to.
///
/// No special permission is required: querying the audio device list
/// and transport type is public metadata.
@interface KYAAudioOutputMonitor : NSObject

@property (weak, nonatomic, nullable) id<KYAAudioOutputMonitorDelegate> delegate;

@property (readonly, nonatomic, getter=isRunning) BOOL running;

/// Whether the most recent observation found an external output device.
/// Exposed for tests and recovery (e.g. wake-from-sleep re-evaluation).
@property (readonly, nonatomic) BOOL hasExternalAudioOutput;

- (void)start;
- (void)stop;

/// Force one synchronous read + delegate notification. No-op when
/// stopped.
- (void)refresh;

@end

@protocol KYAAudioOutputMonitorDelegate <NSObject>
@optional
- (void)audioOutputMonitorDidStartUsingExternalDevice:(KYAAudioOutputMonitor *)monitor;
- (void)audioOutputMonitorDidReturnToBuiltInDevice:(KYAAudioOutputMonitor *)monitor;
@end

NS_ASSUME_NONNULL_END
