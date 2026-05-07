//
//  KYADriveAliveTimer.h
//  KeepingYouAwake
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Periodically rewrites a tiny "ping" file under `NSTemporaryDirectory()`
/// so that the system disk (and any external volume that contains the
/// running app's temp directory) keeps an active I/O footprint. This is
/// the local equivalent of Amphetamine's "Drive Alive".
///
/// `start` is a no-op if already running. `stop` removes the temp file.
/// Instances are intentionally cheap: schedule once per active session,
/// release on session end.
@interface KYADriveAliveTimer : NSObject

/// How frequently the file is rewritten. Defaults to 30 seconds, which
/// is below the spin-down timeout of every external HDD I have seen.
@property (nonatomic, readonly) NSTimeInterval interval;

@property (nonatomic, readonly, getter=isRunning) BOOL running;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithInterval:(NSTimeInterval)interval NS_DESIGNATED_INITIALIZER;

- (void)start;
- (void)stop;

@end

NS_ASSUME_NONNULL_END
