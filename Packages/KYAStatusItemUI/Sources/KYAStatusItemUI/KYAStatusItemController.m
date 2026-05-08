//
//  KYAStatusItemController.m
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 10.09.17.
//  Copyright © 2017 Marcel Dierkes. All rights reserved.
//

#import <KYAStatusItemUI/KYAStatusItemController.h>
#import <KYACommon/KYACommon.h>
#import <KYAStatusItemUI/KYAStatusItemImageProvider.h>
#import "KYAStatusItemUILocalizedStrings.h"

@interface KYAStatusItemController ()
@property (nonatomic, readwrite) NSStatusItem *systemStatusItem;
@property (nonatomic, copy, nullable) NSDate *countdownFireDate;
@property (nonatomic, nullable) NSTimer *countdownTimer;
@property (nonatomic) NSDateComponentsFormatter *countdownFormatter;
@end

@implementation KYAStatusItemController

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        [self configureStatusItem];
    }
    return self;
}

#pragma mark - Configuration

- (void)configureStatusItem
{
    Auto statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    statusItem.highlightMode = ![NSUserDefaults standardUserDefaults].kya_menuBarIconHighlightDisabled;
    if([statusItem respondsToSelector:@selector(behavior)])
    {
        statusItem.behavior = NSStatusItemBehaviorTerminationOnRemoval;
    }
    if([statusItem respondsToSelector:@selector(isVisible)])
    {
        statusItem.visible = YES;
    }
    
    Auto button = statusItem.button;
    
    [button sendActionOn:NSEventMaskLeftMouseUp|NSEventMaskRightMouseUp];
    button.target = self;
    button.action = @selector(toggleStatus:);
    
#if DEBUG
    if(@available(macOS 10.14, *))
    {
        button.contentTintColor = NSColor.systemBlueColor;
    }
    Auto log = KYALogCreateWithCategory("StatusItemUI");
    os_log_debug(log, "Blue status bar item color is enabled for DEBUG builds.");
#endif
    
    self.systemStatusItem = statusItem;
    self.appearance = KYAStatusItemAppearanceInactive;
}

- (void)toggleStatus:(id)sender
{
    Auto delegate = self.delegate;
    Auto event = NSApplication.sharedApplication.currentEvent;
    
    if((event.modifierFlags & NSEventModifierFlagControl)   // ctrl click
       || (event.modifierFlags & NSEventModifierFlagOption) // alt click
       || (event.type == NSEventTypeRightMouseUp))          // right click
    {
        [self showMenuFromDataSource];
        return;
    }
    
    if([delegate respondsToSelector:@selector(statusItemControllerShouldPerformPrimaryAction:)])
    {
        [delegate statusItemControllerShouldPerformPrimaryAction:self];
    }
}

#pragma mark - Appearance

- (KYAStatusItemAppearance)appearance
{
    Auto menubarIcon = KYAStatusItemImageProvider.currentProvider;
    return self.systemStatusItem.image == menubarIcon.activeIconImage;
}

- (void)setAppearance:(KYAStatusItemAppearance)appearance
{
    [self willChangeValueForKey:@"appearance"];
    
    Auto button = self.systemStatusItem.button;
    Auto imageProvider = KYAStatusItemImageProvider.currentProvider;
    
    if(appearance == KYAStatusItemAppearanceActive)
    {
        button.image = imageProvider.activeIconImage;
        button.toolTip = KYA_L10N_CLICK_TO_ALLOW_SLEEP;
    }
    else
    {
        button.image = imageProvider.inactiveIconImage;
        button.toolTip = KYA_L10N_CLICK_TO_PREVENT_SLEEP;
        // Force-clear the countdown when the icon goes back to inactive,
        // even if the caller forgot to call -stopCountdown explicitly.
        [self stopCountdown];
    }

    [self didChangeValueForKey:@"appearance"];
}

#pragma mark - Countdown

- (NSDateComponentsFormatter *)countdownFormatter
{
    if(_countdownFormatter == nil)
    {
        Auto formatter = [NSDateComponentsFormatter new];
        formatter.unitsStyle = NSDateComponentsFormatterUnitsStylePositional;
        formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        formatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
        _countdownFormatter = formatter;
    }
    return _countdownFormatter;
}

- (void)startCountdownWithFireDate:(NSDate *)fireDate
{
    if([NSUserDefaults.standardUserDefaults kya_isMenuBarCountdownDisabled])
    {
        return;
    }
    if(fireDate == nil || [fireDate timeIntervalSinceNow] <= 0)
    {
        [self stopCountdown];
        return;
    }

    self.countdownFireDate = fireDate;
    [self renderCountdown];

    [self.countdownTimer invalidate];
    Auto timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull t) {
        [self renderCountdown];
    }];
    timer.tolerance = 0.25;
    self.countdownTimer = timer;
}

- (void)stopCountdown
{
    [self.countdownTimer invalidate];
    self.countdownTimer = nil;
    self.countdownFireDate = nil;

    Auto button = self.systemStatusItem.button;
    if(button.title.length > 0)
    {
        button.title = @"";
    }
}

- (void)renderCountdown
{
    Auto fireDate = self.countdownFireDate;
    if(fireDate == nil)
    {
        [self stopCountdown];
        return;
    }
    NSTimeInterval remaining = [fireDate timeIntervalSinceNow];
    if(remaining <= 0)
    {
        [self stopCountdown];
        return;
    }
    // Drop hour padding when remaining < 1h to keep the menu bar tidy.
    Auto formatter = self.countdownFormatter;
    formatter.allowedUnits = (remaining >= 3600)
        ? (NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond)
        : (NSCalendarUnitMinute | NSCalendarUnitSecond);
    NSString *text = [formatter stringFromTimeInterval:remaining];
    if(text != nil)
    {
        // Prefix with a hair space so the icon doesn't crowd the digits.
        self.systemStatusItem.button.title = [@" " stringByAppendingString:text];
    }
}

#pragma mark - Menu

- (void)showMenuFromDataSource
{
    Auto dataSource = self.dataSource;
    if([dataSource respondsToSelector:@selector(menuForStatusItemController:)])
    {
        Auto menu = [dataSource menuForStatusItemController:self];
        if(menu != nil)
        {
            [self.systemStatusItem popUpStatusItemMenu:menu];
        }
    }
}

@end
