//
//  KYAActivationSource.m
//  KeepingYouAwake
//
//  Extracted from KYAAppController.m to allow unit testing of the
//  source-aware invariant without depending on KYAAppController's
//  AppKit / NSStatusItem-bound initialization.
//

#import "KYAActivationSource.h"

NSString *KYAActivityLogStringForSource(KYAActivationSource source)
{
    switch(source)
    {
        case KYAActivationSourceWatchedApp:      return KYAActivityLogSourceWatchedApp;
        case KYAActivationSourceWatchedSSID:     return KYAActivityLogSourceWatchedSSID;
        case KYAActivationSourceACPower:         return KYAActivityLogSourceACPower;
        case KYAActivationSourceExternalDisplay: return KYAActivityLogSourceExternalDisplay;
        case KYAActivationSourceSchedule:        return KYAActivityLogSourceSchedule;
        case KYAActivationSourceDownload:        return KYAActivityLogSourceDownload;
        case KYAActivationSourceAudioOutput:     return KYAActivityLogSourceAudioOutput;
        case KYAActivationSourceCPULoad:         return KYAActivityLogSourceCPULoad;
        case KYAActivationSourceUser:
        default:                                 return KYAActivityLogSourceUser;
    }
}
