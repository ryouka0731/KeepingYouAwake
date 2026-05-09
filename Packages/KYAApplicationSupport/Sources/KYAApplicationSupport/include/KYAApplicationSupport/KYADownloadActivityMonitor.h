//
//  KYADownloadActivityMonitor.h
//  KYAApplicationSupport
//
//  Created for KeepingYouAwake-Amphetamine fork (issue #51).
//

#import <Foundation/Foundation.h>
#import <KYACommon/KYAExport.h>

NS_ASSUME_NONNULL_BEGIN

@protocol KYADownloadActivityMonitorDelegate;

/// Polls a list of directories for files whose suffix matches a known
/// "download in progress" pattern (.crdownload, .part, .download, etc.)
/// and notifies its delegate on transitions between "any download in
/// progress" and "no downloads in progress".
@interface KYADownloadActivityMonitor : NSObject

@property (weak, nonatomic, nullable) id<KYADownloadActivityMonitorDelegate> delegate;

/// Default suffixes considered as "in progress". Exposed for tests.
@property (class, nonatomic, readonly) NSArray<NSString *> *defaultInProgressSuffixes;

@property (readonly, nonatomic, getter=isRunning) BOOL running;

/// Replace the watched directories. Each path is `~`-expanded.
/// nil/empty array effectively disables the monitor.
- (void)setDirectories:(nullable NSArray<NSString *> *)directories;

- (void)start;
- (void)stop;

/// Whether the most recent scan found any in-progress download.
/// Exposed for testability.
@property (readonly, nonatomic) BOOL hasInProgressDownload;

/// Force one synchronous scan + notification cycle. Used by tests and
/// to coalesce a wake-from-sleep re-evaluation. Safe to call when
/// stopped.
- (void)scanNow;

@end

@protocol KYADownloadActivityMonitorDelegate <NSObject>
@optional
- (void)downloadActivityMonitorDidStartDownloads:(KYADownloadActivityMonitor *)monitor;
- (void)downloadActivityMonitorDidFinishDownloads:(KYADownloadActivityMonitor *)monitor;
@end

NS_ASSUME_NONNULL_END
