//
//  KYAActivationOwnership.h
//  KeepingYouAwake
//
//  Small testable value object that tracks who started the current
//  activation session. Extracted from `KYAAppController.m` so the
//  source-aware invariant from issue #85 can be unit-tested without
//  instantiating `KYAAppController` (which wires up `NSStatusItem`,
//  asset-catalog images, distributed-notification observers, and OS-
//  level monitors that are not headless-friendly).
//
//  Invariant encoded by this type:
//
//    A feature trigger never deactivates a user-initiated session.
//
//  Each feature trigger (watched-app, watched-SSID, AC power,
//  external-display, schedule, download, audio-output, CPU-load) calls
//  `-terminateIfOwnedBySource:` with its own `KYAActivationSource`. The
//  call is a no-op unless the running session was started with the
//  same source. The `User` path uses `-terminate` (unconditional).
//
//  Thread-safety: this object is expected to be touched on the main
//  thread, matching the rest of `KYAAppController`. No internal locking.
//

#import <Foundation/Foundation.h>
#import "KYAActivationSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface KYAActivationOwnership : NSObject

/// `YES` while a session has been started but not yet terminated.
/// Defaults to `NO`.
@property (nonatomic, readonly, getter=isActive) BOOL active;

/// Who owns the currently active session. Undefined when `active == NO`;
/// callers must gate on `active` before reading.
@property (nonatomic, readonly) KYAActivationSource source;

/// Mark the session as active and record `source` as the owner. Calling
/// this while already active overwrites the source — matching the
/// pre-extraction behavior in `KYAAppController` where every
/// `-activateTimerWithTimeInterval:source:` call unconditionally
/// assigns `self.activationSource = source`.
- (void)startWithSource:(KYAActivationSource)source;

/// Mark the session inactive unconditionally, regardless of source.
/// This is the user-initiated path (status-item click, menu duration,
/// URL scheme, AppleScript, settings-driven shutdowns).
- (void)terminate;

/// Mark the session inactive iff `active == YES` and the recorded
/// source equals `source`. Returns `YES` when termination actually
/// happened (so the caller can decide whether to fire the
/// `KYAActivityLogEndedReasonTriggerCancelled` log entry), `NO`
/// otherwise.
- (BOOL)terminateIfOwnedBySource:(KYAActivationSource)source;

@end

NS_ASSUME_NONNULL_END
