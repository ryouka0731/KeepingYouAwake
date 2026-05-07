//
//  KYAWiFiMonitor.m
//  KYADeviceInfo
//

#import <KYADeviceInfo/KYAWiFiMonitor.h>
#import <CoreWLAN/CoreWLAN.h>
#import <KYACommon/KYACommon.h>

NSNotificationName const KYAWiFiMonitorSSIDDidChangeNotification = @"KYAWiFiMonitorSSIDDidChangeNotification";

@interface KYAWiFiMonitor () <CWEventDelegate>
@property (nonatomic, readwrite, getter=isMonitoring) BOOL monitoring;
@property (nonatomic, nullable) CWWiFiClient *client;
@end

@implementation KYAWiFiMonitor

+ (instancetype)sharedMonitor
{
    static KYAWiFiMonitor *instance;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSString *)currentSSID
{
    Auto interface = CWWiFiClient.sharedWiFiClient.interface;
    Auto ssid = interface.ssid;
    if(ssid.length == 0) { return nil; }
    return ssid;
}

- (void)startMonitoring
{
    if(self.monitoring) { return; }

    Auto client = CWWiFiClient.sharedWiFiClient;
    client.delegate = self;
    self.client = client;

    NSError *error = nil;
    if(![client startMonitoringEventWithType:CWEventTypeSSIDDidChange error:&error])
    {
        NSLog(@"[KYAWiFiMonitor] failed to start SSID monitoring: %@", error);
        return;
    }
    if(![client startMonitoringEventWithType:CWEventTypeLinkDidChange error:&error])
    {
        NSLog(@"[KYAWiFiMonitor] failed to start link monitoring: %@", error);
    }

    self.monitoring = YES;
}

- (void)stopMonitoring
{
    if(!self.monitoring) { return; }

    Auto client = self.client;
    [client stopMonitoringAllEventsAndReturnError:nil];
    if(client.delegate == self)
    {
        client.delegate = nil;
    }
    self.client = nil;
    self.monitoring = NO;
}

- (BOOL)isJoinedNetworkAmongSSIDs:(NSArray<NSString *> *)ssids
{
    Auto current = self.currentSSID;
    if(current.length == 0) { return NO; }
    for(NSString *candidate in ssids)
    {
        if([current caseInsensitiveCompare:candidate] == NSOrderedSame)
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark - CWEventDelegate

- (void)ssidDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName
{
    [self postChangeNotification];
}

- (void)linkDidChangeForWiFiInterfaceWithName:(NSString *)interfaceName
{
    // Link transitions also imply SSID may have become readable/unreadable.
    [self postChangeNotification];
}

- (void)postChangeNotification
{
    Auto block = ^{
        [NSNotificationCenter.defaultCenter postNotificationName:KYAWiFiMonitorSSIDDidChangeNotification
                                                          object:self];
    };
    if(NSThread.isMainThread)
    {
        block();
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@end
