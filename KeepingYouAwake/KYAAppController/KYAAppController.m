//
//  KYAAppController.m
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 17.10.14.
//  Copyright (c) 2014 Marcel Dierkes. All rights reserved.
//

#import "KYAAppController.h"
#import <KYACommon/KYACommon.h>
#import "KYALocalizedStrings.h"
#import "KYAMainMenu.h"
#import "KYABatteryCapacityThreshold.h"
#import "KYAActivationDurationsMenuController.h"
#import "KYAActivationUserNotification.h"
#import "KYADriveAliveTimer.h"

// Deprecated!
#define KYA_MINUTES(m) (m * 60.0f)
#define KYA_HOURS(h) (h * 3600.0f)

@interface KYAAppController () <KYAStatusItemControllerDataSource, KYAStatusItemControllerDelegate, KYAActivationDurationsMenuControllerDelegate, KYASleepWakeTimerDelegate>
@property (nonatomic, readwrite) KYASleepWakeTimer *sleepWakeTimer;
@property (nonatomic, readwrite) KYAStatusItemController *statusItemController;
@property (nonatomic) KYAActivationDurationsMenuController *menuController;

@property (nonatomic) NSTimeInterval workspaceScheduledTimeInterval;

// Battery Status
@property (nonatomic, direct, getter=isBatteryOverrideEnabled) BOOL batteryOverrideEnabled;

// Drive Alive
@property (nonatomic, nullable) KYADriveAliveTimer *driveAliveTimer;
// Continuous AC power observer (separate from activation-lifecycle monitoring)
@property (nonatomic, nullable) id acPowerObserver;

// Menu
@property (nonatomic) NSMenu *menu;
@end

@implementation KYAAppController

#pragma mark - Life Cycle

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        [self configureStatusItemController];
        [self configureSleepWakeTimer];
        [self configureEventHandler];
        [self configureUserNotificationCenter];
        [self configureMainMenu];

        Auto center = NSNotificationCenter.defaultCenter;
        [center addObserver:self
                   selector:@selector(applicationWillFinishLaunching:)
                       name:NSApplicationWillFinishLaunchingNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(applicationDidChangeScreenParameters:)
                       name:NSApplicationDidChangeScreenParametersNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(batteryCapacityThresholdDidChange:)
                       name:kKYABatteryCapacityThresholdDidChangeNotification
                     object:nil];
        
        [self registerForWorkspaceSessionNotifications];
        [self registerForWiFiSSIDNotifications];
        [self reconcileWatchedWiFiSSIDState];
        [self configureACPowerTrigger];

        // Reconcile the AC-power trigger when the user toggles the
        // setting at runtime — without this the trigger only honours
        // the value that was set at app launch.
        [center addObserver:self
                   selector:@selector(userDefaultsDidChange:)
                       name:NSUserDefaultsDidChangeNotification
                     object:NSUserDefaults.standardUserDefaults];
    }
    return self;
}

- (void)dealloc
{
    Auto center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    [center removeObserver:self name:NSApplicationDidChangeScreenParametersNotification object:nil];
    [center removeObserver:self name:kKYABatteryCapacityThresholdDidChangeNotification object:nil];
    [center removeObserver:self name:NSUserDefaultsDidChangeNotification object:NSUserDefaults.standardUserDefaults];

    [self unregisterFromWorkspaceSessionNotifications];
    [self unregisterFromWiFiSSIDNotifications];
    [self teardownACPowerTrigger];
}

- (void)userDefaultsDidChange:(NSNotification *)notification
{
    [self reconcileACPowerTrigger];
}

- (void)reconcileACPowerTrigger
{
    BOOL enabled = [NSUserDefaults.standardUserDefaults kya_isActivateOnACPowerEnabled];
    BOOL active = (self.acPowerObserver != nil);
    if(enabled && !active)
    {
        [self configureACPowerTrigger];
    }
    else if(!enabled && active)
    {
        [self teardownACPowerTrigger];
    }
}

#pragma mark - Main Menu

- (void)configureMainMenu
{
    Auto menuController = [KYAActivationDurationsMenuController new];
    menuController.delegate = self;
    self.menuController = menuController;
    
    self.menu = KYACreateMainMenuWithActivationDurationsSubMenu(menuController.menu);
}

#pragma mark - Status Item Controller

- (void)configureStatusItemController
{
    Auto statusItemController = [KYAStatusItemController new];
    statusItemController.dataSource = self;
    statusItemController.delegate = self;
    self.statusItemController = statusItemController;
}

#pragma mark - Sleep Wake Timer

- (void)configureSleepWakeTimer
{
    Auto sleepWakeTimer = [KYASleepWakeTimer new];
    sleepWakeTimer.delegate = self;
    self.sleepWakeTimer = sleepWakeTimer;
    
    // Activate on launch if needed
    if([NSUserDefaults.standardUserDefaults kya_isActivatedOnLaunch])
    {
        [self activateTimer];
    }
}

- (void)activateTimer
{
    [self activateTimerWithTimeInterval:self.defaultTimeInterval];
}

- (void)activateTimerWithTimeInterval:(NSTimeInterval)timeInterval
{
    // Do not allow negative time intervals
    if(timeInterval < 0)
    {
        return;
    }

    Auto defaults = NSUserDefaults.standardUserDefaults;
    
    Auto timerCompletion = ^(BOOL cancelled) {
        // Post deactivation notification
        if(@available(macOS 11.0, *))
        {
            Auto notification = [[KYAActivationUserNotification alloc] initWithFireDate:nil
                                                                             activating:NO];
            [KYAUserNotificationCenter.sharedCenter postNotification:notification];
        }

        // Quit on timer expiration
        if(cancelled == NO && [defaults kya_isQuitOnTimerExpirationEnabled])
        {
            [NSApplication.sharedApplication terminate:nil];
        }
    };
    [self.sleepWakeTimer scheduleWithTimeInterval:timeInterval completion:timerCompletion];

    // Post activation notification
    if(@available(macOS 11.0, *))
    {
        Auto fireDate = self.sleepWakeTimer.fireDate;
        Auto notification = [[KYAActivationUserNotification alloc] initWithFireDate:fireDate
                                                                         activating:YES];
        [KYAUserNotificationCenter.sharedCenter postNotification:notification];
    }
}

- (void)terminateTimer
{
    [self disableBatteryOverride];

    if([self.sleepWakeTimer isScheduled])
    {
        [self.sleepWakeTimer invalidate];
    }
}

#pragma mark - Default Time Interval

- (NSTimeInterval)defaultTimeInterval
{
    return NSUserDefaults.standardUserDefaults.kya_defaultTimeInterval;
}

#pragma mark - Activate on Launch

- (IBAction)toggleActivateOnLaunch:(id)sender
{
    Auto defaults = NSUserDefaults.standardUserDefaults;
    defaults.kya_activateOnLaunch = ![defaults kya_isActivatedOnLaunch];
    [defaults synchronize];
}

#pragma mark - User Notification Center

- (void)configureUserNotificationCenter
{
    if(@available(macOS 11.0, *))
    {
        Auto center = KYAUserNotificationCenter.sharedCenter;
        [center requestAuthorizationIfUndetermined];
        [center clearAllDeliveredNotifications];
    }
}

#pragma mark - Device Power Monitoring

- (void)checkAndEnableBatteryOverride
{
    Auto batteryMonitor = KYADevice.currentDevice.batteryMonitor;
    CGFloat currentCapacity = batteryMonitor.currentCapacity;
    CGFloat threshold = NSUserDefaults.standardUserDefaults.kya_batteryCapacityThreshold;

    self.batteryOverrideEnabled = (currentCapacity <= threshold);
}

- (void)disableBatteryOverride
{
    self.batteryOverrideEnabled = NO;
}

- (void)deviceParameterDidChange:(NSNotification *)notification
{
    NSParameterAssert(notification);
    
    Auto device = (KYADevice *)notification.object;
    Auto defaults = NSUserDefaults.standardUserDefaults;
    
    Auto userInfo = notification.userInfo;
    Auto deviceParameter = (KYADeviceParameter)userInfo[KYADeviceParameterKey];
    if([deviceParameter isEqualToString:KYADeviceParameterBattery])
    {
        if([self.sleepWakeTimer isScheduled] == NO) { return; }

        if([defaults kya_isDeactivateOnFullChargeEnabled]
           && device.batteryMonitor.state == KYADeviceBatteryStateFull)
        {
            [self terminateTimer];
            return;
        }

        if([defaults kya_isBatteryCapacityThresholdEnabled] == NO) { return; }

        CGFloat threshold = defaults.kya_batteryCapacityThreshold;
        Auto capacity = device.batteryMonitor.currentCapacity;
        if((capacity <= threshold) && ![self isBatteryOverrideEnabled])
        {
            [self terminateTimer];
        }
    }
    else if([deviceParameter isEqualToString:KYADeviceParameterLowPowerMode])
    {
        if([defaults kya_isLowPowerModeMonitoringEnabled] == NO) { return; }
        
        if([device.lowPowerModeMonitor isLowPowerModeEnabled] && [self.sleepWakeTimer isScheduled])
        {
            [self terminateTimer];
        }
    }
}

- (void)enableDevicePowerMonitoring
{
    Auto device = KYADevice.currentDevice;
    Auto center = NSNotificationCenter.defaultCenter;
    Auto defaults = NSUserDefaults.standardUserDefaults;
    
    // Check battery overrides and register for capacity changes.
    [self checkAndEnableBatteryOverride];
    
    [center addObserver:self
               selector:@selector(deviceParameterDidChange:)
                   name:KYADeviceParameterDidChangeNotification
                 object:device];
    
    if([defaults kya_isBatteryCapacityThresholdEnabled]
       || [defaults kya_isDeactivateOnFullChargeEnabled])
       || [defaults kya_isActivateOnACPowerEnabled])
    {
        device.batteryMonitoringEnabled = YES;
    }
    if([defaults kya_isLowPowerModeMonitoringEnabled])
    {
        device.lowPowerModeMonitoringEnabled = YES;
    }
}

- (void)disableDevicePowerMonitoring
{
    Auto device = KYADevice.currentDevice;
    Auto center = NSNotificationCenter.defaultCenter;
    Auto defaults = NSUserDefaults.standardUserDefaults;

    [center removeObserver:self
                      name:KYADeviceParameterDidChangeNotification
                    object:device];

    // The AC-power trigger uses a block-based observer (unaffected by the
    // selector-based removal above) and needs the battery monitor to keep
    // emitting notifications, so leave the flag on while it is engaged.
    if([defaults kya_isActivateOnACPowerEnabled] == NO)
    {
        device.batteryMonitoringEnabled = NO;
    }
    device.lowPowerModeMonitoringEnabled = NO;
}

#pragma mark - AC Power Trigger

- (void)configureACPowerTrigger
{
    if([NSUserDefaults.standardUserDefaults kya_isActivateOnACPowerEnabled] == NO) { return; }

    Auto device = KYADevice.currentDevice;
    device.batteryMonitoringEnabled = YES;

    AutoWeak weakSelf = self;
    self.acPowerObserver = [NSNotificationCenter.defaultCenter
        addObserverForName:KYADeviceParameterDidChangeNotification
                    object:device
                     queue:NSOperationQueue.mainQueue
                usingBlock:^(NSNotification *note) {
        Auto userInfo = note.userInfo;
        Auto param = (KYADeviceParameter)userInfo[KYADeviceParameterKey];
        if(![param isEqualToString:KYADeviceParameterBattery]) { return; }
        [weakSelf evaluateACPowerState];
    }];

    [self evaluateACPowerState];
}

- (void)teardownACPowerTrigger
{
    if(self.acPowerObserver != nil)
    {
        [NSNotificationCenter.defaultCenter removeObserver:self.acPowerObserver];
        self.acPowerObserver = nil;
    }
}

- (void)evaluateACPowerState
{
    if([NSUserDefaults.standardUserDefaults kya_isActivateOnACPowerEnabled] == NO) { return; }

    Auto state = KYADevice.currentDevice.batteryMonitor.state;
    BOOL onAC = (state == KYADeviceBatteryStateCharging
                 || state == KYADeviceBatteryStateFull);
    BOOL scheduled = [self.sleepWakeTimer isScheduled];

    if(onAC && !scheduled)
    {
        [self activateTimerWithTimeInterval:KYASleepWakeTimeIntervalIndefinite];
    }
    else if(state == KYADeviceBatteryStateUnplugged && scheduled)
    {
        [self terminateTimer];
    }
    // KYADeviceBatteryStateUnknown (no battery / desktop Mac) → no-op.
}

#pragma mark - Battery Capacity Threshold Changes

- (void)batteryCapacityThresholdDidChange:(NSNotification *)notification
{
    if([self.sleepWakeTimer isScheduled])
    {
        [self terminateTimer];
    }
}

#pragma mark - Workspace Session Handling

- (void)registerForWorkspaceSessionNotifications
{
    Auto workspaceCenter = NSWorkspace.sharedWorkspace.notificationCenter;
    [workspaceCenter addObserver:self
                        selector:@selector(workspaceSessionDidBecomeActive:)
                            name:NSWorkspaceSessionDidBecomeActiveNotification
                          object:nil];
    [workspaceCenter addObserver:self
                        selector:@selector(workspaceSessionDidResignActive:)
                            name:NSWorkspaceSessionDidResignActiveNotification
                          object:nil];
}

- (void)unregisterFromWorkspaceSessionNotifications
{
    Auto workspaceCenter = NSWorkspace.sharedWorkspace.notificationCenter;
    [workspaceCenter removeObserver:self
                               name:NSWorkspaceSessionDidBecomeActiveNotification
                             object:nil];
    [workspaceCenter removeObserver:self
                               name:NSWorkspaceSessionDidResignActiveNotification
                             object:nil];
}

- (void)workspaceSessionDidBecomeActive:(NSNotification *)notification
{
    Auto defaults = NSUserDefaults.standardUserDefaults;
    if([defaults kya_isDeactivateOnUserSwitchEnabled] && self.workspaceScheduledTimeInterval >= 0)
    {
        [self activateTimerWithTimeInterval:self.workspaceScheduledTimeInterval];
        self.workspaceScheduledTimeInterval = -1;
    }
}

- (void)workspaceSessionDidResignActive:(NSNotification *)notification
{
    Auto defaults = NSUserDefaults.standardUserDefaults;
    if([defaults kya_isDeactivateOnUserSwitchEnabled] && [self.sleepWakeTimer isScheduled])
    {
        self.workspaceScheduledTimeInterval = self.sleepWakeTimer.scheduledTimeInterval;
        [self terminateTimer];
    }
}

#pragma mark - Watched Wi-Fi SSID

- (void)registerForWiFiSSIDNotifications
{
    Auto monitor = KYAWiFiMonitor.sharedMonitor;
    Auto defaults = NSUserDefaults.standardUserDefaults;
    if(defaults.kya_watchedWiFiSSIDs.count > 0)
    {
        [monitor startMonitoring];
    }

    Auto center = NSNotificationCenter.defaultCenter;
    [center addObserver:self
               selector:@selector(watchedWiFiSSIDDidChange:)
                   name:KYAWiFiMonitorSSIDDidChangeNotification
                 object:monitor];
}

- (void)unregisterFromWiFiSSIDNotifications
{
    Auto center = NSNotificationCenter.defaultCenter;
    [center removeObserver:self
                      name:KYAWiFiMonitorSSIDDidChangeNotification
                    object:KYAWiFiMonitor.sharedMonitor];
    [KYAWiFiMonitor.sharedMonitor stopMonitoring];
}

- (void)reconcileWatchedWiFiSSIDState
{
    Auto ssids = NSUserDefaults.standardUserDefaults.kya_watchedWiFiSSIDs;
    if(ssids.count == 0) { return; }
    if([KYAWiFiMonitor.sharedMonitor isJoinedNetworkAmongSSIDs:ssids] == NO) { return; }

    Auto sleepWakeTimer = self.sleepWakeTimer;
    BOOL scheduled = [sleepWakeTimer isScheduled];
    // Mirror watchedWiFiSSIDDidChange: an in-progress finite session
    // (e.g., one started by `kya_isActivatedOnLaunch` with a finite
    // default duration) must be upgraded to indefinite while joined
    // to a watched SSID, otherwise it expires mid-connection.
    BOOL alreadyIndefinite = scheduled
        && sleepWakeTimer.scheduledTimeInterval == KYASleepWakeTimeIntervalIndefinite;
    if(alreadyIndefinite) { return; }
    if(scheduled) { [self terminateTimer]; }
    [self activateTimerWithTimeInterval:KYASleepWakeTimeIntervalIndefinite];
}

- (void)watchedWiFiSSIDDidChange:(NSNotification *)notification
{
    Auto ssids = NSUserDefaults.standardUserDefaults.kya_watchedWiFiSSIDs;
    if(ssids.count == 0) { return; }
    Auto monitor = KYAWiFiMonitor.sharedMonitor;
    BOOL onWatchedNetwork = [monitor isJoinedNetworkAmongSSIDs:ssids];
    Auto sleepWakeTimer = self.sleepWakeTimer;
    BOOL scheduled = [sleepWakeTimer isScheduled];

    if(onWatchedNetwork)
    {
        // While joined to a watched network the user expects activation
        // to last for the duration of the connection. Either start an
        // indefinite session, or upgrade an in-progress finite session
        // so it doesn't expire mid-connection.
        BOOL alreadyIndefinite = scheduled
            && sleepWakeTimer.scheduledTimeInterval == KYASleepWakeTimeIntervalIndefinite;
        if(alreadyIndefinite) { return; }
        if(scheduled) { [self terminateTimer]; }
        [self activateTimerWithTimeInterval:KYASleepWakeTimeIntervalIndefinite];
    }
    else if(scheduled)
    {
        [self terminateTimer];
    }
}

#pragma mark - Event Handling

- (void)applicationWillFinishLaunching:(NSNotification *)notification
{
    [KYAEventHandler.defaultHandler registerAsDefaultEventHandler];
}

- (void)configureEventHandler
{
    Auto eventHandler = KYAEventHandler.defaultHandler;
    
    AutoWeak weakSelf = self;
    [eventHandler registerActionNamed:@"activate" block:^(KYAEvent *event) {
        [weakSelf handleActivateActionForEvent:event];
    }];
    
    [eventHandler registerActionNamed:@"deactivate" block:^(KYAEvent *event) {
        Auto strongSelf = weakSelf;
        [strongSelf terminateTimer];
        strongSelf.statusItemController.appearance = KYAStatusItemAppearanceInactive;
    }];
    
    [eventHandler registerActionNamed:@"toggle" block:^(KYAEvent *event) {
        Auto strongSelf = weakSelf;
        [strongSelf statusItemControllerShouldPerformPrimaryAction:strongSelf.statusItemController];
    }];
}

- (void)handleActivateActionForEvent:(KYAEvent *)event
{
    Auto parameters = event.arguments;
    NSString *seconds = parameters[@"seconds"];
    NSString *minutes = parameters[@"minutes"];
    NSString *hours = parameters[@"hours"];

    [self terminateTimer];
    
    Auto statusItemController = self.statusItemController;

    // Activate indefinitely if there are no parameters
    if(parameters == nil || parameters.count == 0)
    {
        [self activateTimer];
        statusItemController.appearance = KYAStatusItemAppearanceActive;
    }
    else if(seconds != nil)
    {
        [self activateTimerWithTimeInterval:(NSTimeInterval)ceil(seconds.doubleValue)];
        statusItemController.appearance = KYAStatusItemAppearanceActive;
    }
    else if(minutes != nil)
    {
        [self activateTimerWithTimeInterval:(NSTimeInterval)KYA_MINUTES(ceil(minutes.doubleValue))];
        statusItemController.appearance = KYAStatusItemAppearanceActive;
    }
    else if(hours != nil)
    {
        [self activateTimerWithTimeInterval:(NSTimeInterval)KYA_HOURS(ceil(hours.doubleValue))];
        statusItemController.appearance = KYAStatusItemAppearanceActive;
    }
    else
    {
        statusItemController.appearance = KYAStatusItemAppearanceInactive;
    }
}

#pragma mark - Internal / External Screen Parameter Changes

- (void)applicationDidChangeScreenParameters:(NSNotification *)notification
{
    if([NSUserDefaults.standardUserDefaults kya_isActivateOnExternalDisplayConnectedEnabled] == NO)
    {
        return;
    }
    
    NSUInteger numberOfExternalScreens = KYADisplayParametersGetNumberOfExternalDisplays();
    Auto sleepWakeTimer = self.sleepWakeTimer;
    
    if(numberOfExternalScreens == 0)
    {
        // Only the main screen is connected, deactivate!
        if([sleepWakeTimer isScheduled])
        {
            [self terminateTimer];
        }
    }
    else
    {
        // The main screen and at least one external screen, activate!
        if([sleepWakeTimer isScheduled] == NO)
        {
            [self activateTimer];
        }
    }
}

#pragma mark - KYAStatusItemControllerDataSource

- (NSMenu *)menuForStatusItemController:(KYAStatusItemController *)controller
{
    return self.menu;
}

#pragma mark - KYAStatusItemControllerDelegate

- (void)statusItemControllerShouldPerformPrimaryAction:(KYAStatusItemController *)controller
{
    if([self.sleepWakeTimer isScheduled])
    {
        [self terminateTimer];
    }
    else
    {
        [self activateTimer];
    }
}

#pragma mark - KYAActivationDurationsMenuControllerDelegate

- (KYAActivationDuration *)currentActivationDuration
{
    Auto sleepWakeTimer = self.sleepWakeTimer;
    if(![sleepWakeTimer isScheduled])
    {
        return nil;
    }

    NSTimeInterval seconds = sleepWakeTimer.scheduledTimeInterval;
    return [[KYAActivationDuration alloc] initWithSeconds:seconds];
}

- (void)activationDurationsMenuController:(KYAActivationDurationsMenuController *)controller didSelectActivationDuration:(KYAActivationDuration *)activationDuration
{
    [self terminateTimer];

    AutoWeak weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSTimeInterval seconds = activationDuration.seconds;
        [weakSelf activateTimerWithTimeInterval:seconds];
    });
}

- (NSDate *)fireDateForMenuController:(KYAActivationDurationsMenuController *)controller
{
    return self.sleepWakeTimer.fireDate;
}

#pragma mark - KYASleepWakeTimerDelegate

- (void)sleepWakeTimer:(KYASleepWakeTimer *)sleepWakeTimer willActivateWithTimeInterval:(NSTimeInterval)timeInterval
{
    // Update the status item
    self.statusItemController.appearance = KYAStatusItemAppearanceActive;

    [self enableDevicePowerMonitoring];
    [self startDriveAliveIfEnabled];
}

- (void)sleepWakeTimerDidDeactivate:(KYASleepWakeTimer *)sleepWakeTimer
{
    // Update the status item
    self.statusItemController.appearance = KYAStatusItemAppearanceInactive;

    [self disableDevicePowerMonitoring];
    [self stopDriveAlive];
}

#pragma mark - Drive Alive

- (void)startDriveAliveIfEnabled
{
    if([NSUserDefaults.standardUserDefaults kya_isDriveAliveEnabled] == NO) { return; }
    if(self.driveAliveTimer.isRunning) { return; }

    self.driveAliveTimer = [[KYADriveAliveTimer alloc] initWithInterval:30.0];
    [self.driveAliveTimer start];
}

- (void)stopDriveAlive
{
    [self.driveAliveTimer stop];
    self.driveAliveTimer = nil;
}

@end
