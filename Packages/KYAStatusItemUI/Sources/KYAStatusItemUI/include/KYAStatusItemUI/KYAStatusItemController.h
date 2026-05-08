//
//  KYAStatusItemController.h
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 10.09.17.
//  Copyright © 2017 Marcel Dierkes. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <KYAApplicationSupport/KYAApplicationSupport.h>

NS_ASSUME_NONNULL_BEGIN

/// The appearance of the status item icon image.
typedef NS_ENUM(NSUInteger, KYAStatusItemAppearance)
{
    /// Represents the inactive state of the status bar item
    KYAStatusItemAppearanceInactive = 0,
    /// Represents the active state of the status bar item
    KYAStatusItemAppearanceActive
};

@protocol KYAStatusItemControllerDataSource;
@protocol KYAStatusItemControllerDelegate;

/// Manages the display and interaction with the menu bar status item.
@interface KYAStatusItemController : NSObject

/// The underlying system status bar item.
@property (nonatomic, readonly) NSStatusItem *systemStatusItem;

/// Controls the activate/inactive appearance of the status item image.
@property (nonatomic) KYAStatusItemAppearance appearance;

/// Starts a one-second-tick UI timer that updates the status item's
/// title to show the time remaining until \c fireDate. No-op if the
/// fire date is in the past or if the user has disabled the countdown
/// via \c kya_menuBarCountdownDisabled.
/// @param fireDate The moment at which the active session will end.
- (void)startCountdownWithFireDate:(NSDate *)fireDate;

/// Stops the countdown timer and clears the status item title so that
/// only the icon is shown.
- (void)stopCountdown;

/// A delegate for receiving click events.
@property (weak, nonatomic, nullable) id<KYAStatusItemControllerDataSource> dataSource;

/// A delegate for receiving click events.
@property (weak, nonatomic, nullable) id<KYAStatusItemControllerDelegate> delegate;

/// The designated initializer.
- (instancetype)init NS_DESIGNATED_INITIALIZER;

@end

@protocol KYAStatusItemControllerDataSource <NSObject>
@optional
/// The menu that is displayed when the status item is clicked.
- (nullable NSMenu *)menuForStatusItemController:(KYAStatusItemController *)controller;
@end

@protocol KYAStatusItemControllerDelegate <NSObject>
@optional
/// Notifies the delegate that the primary click action was invoked.
/// @param controller The delegating status item controller
- (void)statusItemControllerShouldPerformPrimaryAction:(KYAStatusItemController *)controller;
@end

NS_ASSUME_NONNULL_END
