//
//  KYAMouseJiggler.h
//  KYAApplicationSupport
//
//  Created for KeepingYouAwake-Amphetamine fork (issue #53).
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

/// Periodically nudges the cursor by 1px so external systems that key
/// off `CGEventSourceSecondsSinceLastEventType(... kCGAnyInputEventType)`
/// (rather than the caffeinate-style assertion API) see continuous
/// activity. Most chat apps that mark you "Away" after N minutes of
/// idle fall in this category — caffeinate alone won't keep them
/// active, but a tiny mouse-move every minute will.
///
/// On macOS 10.15+ posting `CGEvent`s requires the host app to be
/// granted **Accessibility** permission (System Settings → Privacy &
/// Security → Accessibility). Without it, `CGEventPost` silently
/// no-ops and this class effectively does nothing.
///
/// Off by default. Opt in via `kya_mouseJigglerEnabled = YES` and grant
/// Accessibility to KYA.
@interface KYAMouseJiggler : NSObject

/// YES while the jiggler is ticking.
@property (readonly, nonatomic, getter=isRunning) BOOL running;

/// Tick interval in seconds. Default: 60.
@property (nonatomic) NSTimeInterval interval;

/// Begin nudging. Safe to call multiple times.
- (void)start;

/// Stop nudging.
- (void)stop;

/// One-shot nudge — used by tests and for the wake-from-sleep refresh.
/// Performs the +1px / -1px cursor displacement once.
- (void)nudgeOnce;

@end

NS_ASSUME_NONNULL_END
