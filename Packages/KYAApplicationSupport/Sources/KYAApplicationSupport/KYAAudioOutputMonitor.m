//
//  KYAAudioOutputMonitor.m
//  KYAApplicationSupport
//

#import <KYAApplicationSupport/KYAAudioOutputMonitor.h>
#import <KYACommon/KYACommon.h>
#import <CoreAudio/CoreAudio.h>

@interface KYAAudioOutputMonitor ()
@property (nonatomic, readwrite, getter=isRunning) BOOL running;
@property (nonatomic, readwrite) BOOL hasExternalAudioOutput;
@end

static OSStatus KYAAudioOutputMonitorPropertyCallback(AudioObjectID inObjectID,
                                                      UInt32 inNumberAddresses,
                                                      const AudioObjectPropertyAddress *inAddresses,
                                                      void *inClientData);

@implementation KYAAudioOutputMonitor

#pragma mark - Lifecycle

- (void)dealloc
{
    [self stop];
}

- (void)start
{
    if(self.running) { return; }
    self.running = YES;

    AudioObjectPropertyAddress address = {
        .mSelector = kAudioHardwarePropertyDefaultOutputDevice,
        .mScope    = kAudioObjectPropertyScopeGlobal,
        .mElement  = kAudioObjectPropertyElementMain,
    };
    OSStatus status = AudioObjectAddPropertyListener(kAudioObjectSystemObject,
                                                     &address,
                                                     &KYAAudioOutputMonitorPropertyCallback,
                                                     (__bridge void *)self);
    if(status != noErr)
    {
        // Listener registration failed — fall back to "running" but
        // never auto-fire. Refresh-on-demand still works.
        return;
    }
    [self refresh];
}

- (void)stop
{
    if(!self.running) { return; }
    self.running = NO;

    AudioObjectPropertyAddress address = {
        .mSelector = kAudioHardwarePropertyDefaultOutputDevice,
        .mScope    = kAudioObjectPropertyScopeGlobal,
        .mElement  = kAudioObjectPropertyElementMain,
    };
    AudioObjectRemovePropertyListener(kAudioObjectSystemObject,
                                      &address,
                                      &KYAAudioOutputMonitorPropertyCallback,
                                      (__bridge void *)self);
}

#pragma mark - Public API

- (void)refresh
{
    BOOL isExternal = [self currentDefaultOutputIsExternal];
    if(isExternal == self.hasExternalAudioOutput) { return; }
    self.hasExternalAudioOutput = isExternal;

    Auto delegate = self.delegate;
    if(isExternal)
    {
        if([delegate respondsToSelector:@selector(audioOutputMonitorDidStartUsingExternalDevice:)])
        {
            [delegate audioOutputMonitorDidStartUsingExternalDevice:self];
        }
    }
    else
    {
        if([delegate respondsToSelector:@selector(audioOutputMonitorDidReturnToBuiltInDevice:)])
        {
            [delegate audioOutputMonitorDidReturnToBuiltInDevice:self];
        }
    }
}

#pragma mark - Internal

- (BOOL)currentDefaultOutputIsExternal
{
    AudioDeviceID deviceID = 0;
    UInt32 size = sizeof(deviceID);
    AudioObjectPropertyAddress defaultAddr = {
        .mSelector = kAudioHardwarePropertyDefaultOutputDevice,
        .mScope    = kAudioObjectPropertyScopeGlobal,
        .mElement  = kAudioObjectPropertyElementMain,
    };
    OSStatus status = AudioObjectGetPropertyData(kAudioObjectSystemObject,
                                                 &defaultAddr,
                                                 0, NULL,
                                                 &size, &deviceID);
    if(status != noErr || deviceID == 0) { return NO; }

    UInt32 transportType = 0;
    UInt32 transportSize = sizeof(transportType);
    AudioObjectPropertyAddress transportAddr = {
        .mSelector = kAudioDevicePropertyTransportType,
        .mScope    = kAudioObjectPropertyScopeGlobal,
        .mElement  = kAudioObjectPropertyElementMain,
    };
    status = AudioObjectGetPropertyData(deviceID,
                                        &transportAddr,
                                        0, NULL,
                                        &transportSize, &transportType);
    if(status != noErr) { return NO; }

    // Built-in is the only "internal" transport. Everything else
    // (Bluetooth, USB, HDMI, AirPlay, virtual, FireWire, Thunderbolt,
    // unknown, …) counts as external. `Continuity` (Mac-as-mic via
    // iPhone) is also reasonably treated as external.
    return (transportType != kAudioDeviceTransportTypeBuiltIn);
}

@end

#pragma mark - Core Audio listener callback

static OSStatus KYAAudioOutputMonitorPropertyCallback(AudioObjectID inObjectID,
                                                      UInt32 inNumberAddresses,
                                                      const AudioObjectPropertyAddress *inAddresses,
                                                      void *inClientData)
{
    (void)inObjectID;
    (void)inNumberAddresses;
    (void)inAddresses;
    KYAAudioOutputMonitor *monitor = (__bridge KYAAudioOutputMonitor *)inClientData;
    // Hop to the main queue: delegate calls drive AppKit code paths.
    dispatch_async(dispatch_get_main_queue(), ^{
        [monitor refresh];
    });
    return noErr;
}
