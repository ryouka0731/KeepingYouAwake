//
//  KYAAppDelegate.m
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 17.10.14.
//  Copyright (c) 2014 Marcel Dierkes. All rights reserved.
//

#import "KYAAppDelegate.h"
#import <KYACommon/KYACommon.h>
#import "KYAAppUpdater.h"
#import "KYASettingsWindow.h"
#import "KYAUpdateSettingsViewController.h"

@interface KYAAppDelegate ()
@property (weak, nonatomic, nullable) KYASettingsWindow *settingsWindow;
@end

@implementation KYAAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
#if KYA_APP_UPDATER_ENABLED
    [KYAAppUpdater defaultAppUpdater];
#endif
    
    if(@available(macOS 13.0, *))
    {
        [NSApplication.sharedApplication kya_migrateLaunchAtLoginToAppServiceIfNeeded];
    }
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)hasVisibleWindows
{
    // Let's ignore all reopen requests in the first 5 seconds of the app's runtime.
    // Sometimes multiple reopen events are sent on app launch, which we don't want to handle.
    Auto launchDate = NSRunningApplication.currentApplication.launchDate;
    if(hasVisibleWindows == NO && [[launchDate dateByAddingTimeInterval:5.0f] compare:[NSDate date]] == NSOrderedAscending)
    {
        [self showSettingsWindow:sender];
    }
    return NO;
}

#pragma mark - Settings Window

- (void)showSettingsWindow:(id)sender
{
    if(@available(macOS 14.0, *))
    {
        [NSApplication.sharedApplication activate];
    }
    else
    {
        [NSApplication.sharedApplication activateIgnoringOtherApps:YES];
    }
    
    AutoVar settingsWindow = self.settingsWindow;
    if(settingsWindow == nil)
    {
        NSArray<NSTabViewItem *> *additionalTabViewItems;
#if KYA_APP_UPDATER_ENABLED
        additionalTabViewItems = @[KYAUpdateSettingsViewController.preferredTabViewItem];
#endif
        settingsWindow = [[KYASettingsWindow alloc] initWithAdditionalTabViewItems:additionalTabViewItems];
        self.settingsWindow = settingsWindow;
    }
    [settingsWindow makeKeyAndOrderFront:sender];
}

#pragma mark - Activity Log

- (void)showActivityLog:(id)sender
{
    NSURL *url = KYAActivityLogger.sharedLogger.fileURL;
    Auto fileManager = NSFileManager.defaultManager;
    if(![fileManager fileExistsAtPath:url.path])
    {
        // Touch an empty file so the user has something to open even if
        // no session has been recorded yet (and so the editor's
        // file-watch picks up future appends without re-opening).
        [@"" writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    [NSWorkspace.sharedWorkspace openURL:url];
}

@end
