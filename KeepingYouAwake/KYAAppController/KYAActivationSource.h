//
//  KYAActivationSource.h
//  KeepingYouAwake
//
//  Extracted from KYAAppController.m to allow unit testing of the
//  source-aware invariant without depending on KYAAppController's
//  AppKit / NSStatusItem-bound initialization.
//

#import <Foundation/Foundation.h>
#import <KYAApplicationSupport/KYAApplicationSupport.h>

NS_ASSUME_NONNULL_BEGIN

/// Tracks who started the current activation session. Feature triggers
/// (watched-app, watched-SSID, AC power, external-display, schedule,
/// download, audio-output, CPU-load) only deactivate when their own
/// `KYAActivationSource` matches the session, so a feature signal can't
/// terminate a user-initiated timer. The default is `User`, covering the
/// status-item click, menu duration, URL scheme, AppleScript, and
/// `kya_isActivatedOnLaunch` paths.
typedef NS_ENUM(NSInteger, KYAActivationSource) {
    KYAActivationSourceUser = 0,
    KYAActivationSourceWatchedApp,
    KYAActivationSourceWatchedSSID,
    KYAActivationSourceACPower,
    KYAActivationSourceExternalDisplay,
    KYAActivationSourceSchedule,
    KYAActivationSourceDownload,
    KYAActivationSourceAudioOutput,
    KYAActivationSourceCPULoad,
};

/// Maps a `KYAActivationSource` enum value to the matching
/// `KYAActivityLogSource*` string constant declared in `KYAActivityLogger.h`.
///
/// The function is total over the enum domain: any input — including
/// values outside the declared range, which can legitimately appear via
/// `(KYAActivationSource)integer` casts — maps to a non-nil, non-empty
/// `NSString *`. Unknown values fall back to `KYAActivityLogSourceUser`,
/// matching the production behavior in `KYAAppController.m` where the
/// `User` case shares the `default:` branch.
FOUNDATION_EXPORT NSString *KYAActivityLogStringForSource(KYAActivationSource source);

NS_ASSUME_NONNULL_END
