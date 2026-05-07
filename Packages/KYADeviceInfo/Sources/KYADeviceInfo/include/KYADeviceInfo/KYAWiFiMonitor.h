//
//  KYAWiFiMonitor.h
//  KYADeviceInfo
//

#import <Foundation/Foundation.h>
#import <KYACommon/KYAExport.h>

NS_ASSUME_NONNULL_BEGIN

/// Posted on the main queue whenever the joined Wi-Fi SSID changes
/// (including transitions to/from no Wi-Fi at all). The notification's
/// object is the `KYAWiFiMonitor` instance that observed the change.
KYA_EXPORT NSNotificationName const KYAWiFiMonitorSSIDDidChangeNotification;

/// Wraps `CWWiFiClient` to expose the currently joined SSID and emit a
/// uniform notification on changes. Reading the SSID on macOS 14+
/// requires Location authorization; without it `currentSSID` returns
/// `nil` even when the Mac is connected. KYAWiFiMonitor does not
/// request that authorization itself — call sites should arrange the
/// prompt at a moment that makes sense to the user.
@interface KYAWiFiMonitor : NSObject

/// Lazily-instantiated singleton tied to the system's Wi-Fi client.
@property (class, nonatomic, readonly) KYAWiFiMonitor *sharedMonitor;

/// The SSID of the joined network on the default Wi-Fi interface, or
/// `nil` if Wi-Fi is off, no network is joined, or the SSID is not
/// readable due to missing authorization.
@property (copy, nonatomic, readonly, nullable) NSString *currentSSID;

/// Returns `YES` while monitoring is active. Toggle with
/// `startMonitoring` / `stopMonitoring`.
@property (nonatomic, readonly, getter=isMonitoring) BOOL monitoring;

- (void)startMonitoring;
- (void)stopMonitoring;

/// Returns `YES` when one of `ssids` matches `currentSSID`
/// case-insensitively. `nil` or empty `currentSSID` always returns `NO`.
- (BOOL)isJoinedNetworkAmongSSIDs:(NSArray<NSString *> *)ssids;

@end

NS_ASSUME_NONNULL_END
