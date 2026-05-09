//
//  KYALocalizedStrings.c
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 10.08.19.
//  Copyright © 2019 Marcel Dierkes. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - Generic

#define KYA_L10N_OK NSLocalizedString(@"OK", @"OK")
#define KYA_L10N_CANCEL NSLocalizedString(@"Cancel", @"Cancel")
#define KYA_L10N_DEFAULT NSLocalizedString(@"Default", @"Default")

#pragma mark - Main Menu

#define KYA_L10N_ACTIVATE_FOR_DURATION NSLocalizedString(@"Activate for Duration", @"Activate for Duration")
#define KYA_L10N_SETTINGS_ELLIPSIS NSLocalizedString(@"Settings…", @"Settings…")
#define KYA_L10N_SHOW_ACTIVITY_LOG_ELLIPSIS NSLocalizedString(@"Show Activity Log…", @"Show Activity Log…")
#define KYA_L10N_QUIT NSLocalizedString(@"Quit", @"Quit")

#pragma mark -

#define KYA_L10N_IS_DEFAULT_SUFFIX NSLocalizedString(@"(Default)", @"(Default)")

#define KYA_L10N_DURATION_ALREADY_ADDED NSLocalizedString(@"This duration has already been added.", @"This duration has already been added.")

#define KYA_L10N_DURATION_INVALID_INPUT NSLocalizedString(@"The entered duration is invalid. Please try again.", @"The entered duration is invalid. Please try again.")

#define KYA_L10N_INDEFINITELY NSLocalizedString(@"Indefinitely", @"Indefinitely")

#define KYA_L10N_UNTIL_END_OF_DAY NSLocalizedString(@"Until end of day", @"Until end of day")

#define KYA_L10N_VERSION NSLocalizedString(@"Version", @"Version")

#pragma mark - Notifications

#define KYA_L10N_PREVENTING_SLEEP_INDEFINITELY_TITLE NSLocalizedString(@"Preventing Sleep", @"Preventing Sleep")

#define KYA_L10N_PREVENTING_SLEEP_INDEFINITELY_BODY_TEXT NSLocalizedString(@"You can still manually enable sleep mode for your Mac.", @"You can still manually enable sleep mode for your Mac.")

#define KYA_L10N_FORMAT_PREVENTING_SLEEP_FOR_TIME_TITLE NSLocalizedString(@"Preventing Sleep for %@", @"Preventing Sleep for %@")
#define KYA_L10N_PREVENTING_SLEEP_FOR_TIME_TITLE(_str) [NSString stringWithFormat:KYA_L10N_FORMAT_PREVENTING_SLEEP_FOR_TIME_TITLE, (NSString *)(_str)]

#define KYA_L10N_PREVENTING_SLEEP_FOR_TIME_BODY_TEXT NSLocalizedString(@"Afterwards your Mac will automatically go to sleep again when unused.", @"Afterwards your Mac will automatically go to sleep again when unused.")

#define KYA_L10N_ALLOWING_SLEEP_TITLE NSLocalizedString(@"Allowing Sleep", @"Allowing Sleep")

#define KYA_L10N_ALLOWING_SLEEP_BODY_TEXT NSLocalizedString(@"Your Mac will automatically go to sleep when unused.", @"Your Mac will automatically go to sleep when unused.")

#pragma mark - Settings

#define KYA_L10N_QUIT_ON_TIMER_EXPIRATION NSLocalizedString(@"Quit when activation duration is over", @"Quit when activation duration is over")
#define KYA_L10N_ALLOW_DISPLAY_SLEEP NSLocalizedString(@"Allow the display to sleep", @"Allow the display to sleep")
#define KYA_L10N_PREVENT_DISK_SLEEP NSLocalizedString(@"Prevent the disk from sleeping", @"Prevent the disk from sleeping")
#define KYA_L10N_ACTIVATE_ON_EXTERNAL_DISPLAY NSLocalizedString(@"Activate when an external display is connected", @"Activate when an external display is connected")
#define KYA_L10N_DEACTIVATE_ON_USER_SWITCH NSLocalizedString(@"Deactivate when switched to another user account", @"Deactivate when switched to another user account")
#define KYA_L10N_DEACTIVATE_ON_FULL_CHARGE NSLocalizedString(@"Deactivate when battery is fully charged", @"Deactivate when battery is fully charged")
#define KYA_L10N_DRIVE_ALIVE NSLocalizedString(@"Keep external drives spinning while active", @"Keep external drives spinning while active")
#define KYA_L10N_ACTIVATE_ON_AC_POWER NSLocalizedString(@"Activate while on AC power", @"Activate while on AC power")
#define KYA_L10N_HIDE_MENU_BAR_COUNTDOWN NSLocalizedString(@"Hide the remaining time countdown in the menu bar", @"Hide the remaining time countdown in the menu bar")
#define KYA_L10N_ACTIVATE_DURING_SCHEDULE NSLocalizedString(@"Activate during scheduled hours", @"Activate during scheduled hours")
#define KYA_L10N_ACTIVATE_WHILE_DOWNLOADING NSLocalizedString(@"Activate while a download is in progress", @"Activate while a download is in progress")
#define KYA_L10N_MOUSE_JIGGLER NSLocalizedString(@"Nudge the cursor every minute while active (requires Accessibility permission)", @"Nudge the cursor every minute while active (requires Accessibility permission)")
#define KYA_L10N_DURATIONS_ALERT_REALLY_RESET_TITLE NSLocalizedString(@"Reset Activation Durations", @"Reset Activation Durations")
#define KYA_L10N_DURATIONS_ALERT_REALLY_RESET_MESSAGE NSLocalizedString(@"Do you really want to reset the activation durations to the default values?", @"Do you really want to reset the activation durations to the default values?")

#define KYA_L10N_SET_DEFAULT_ACTIVATION_DURATION(_str) [NSString stringWithFormat:NSLocalizedString(@"Set Default: %@", @"Set Default: %@"), (NSString *)(_str)]
