//
//  KYAActivationOwnership.m
//  KeepingYouAwake
//
//  See header for the invariant this type encodes.
//

#import "KYAActivationOwnership.h"

@interface KYAActivationOwnership ()
@property (nonatomic, readwrite, getter=isActive) BOOL active;
@property (nonatomic, readwrite) KYAActivationSource source;
@end

@implementation KYAActivationOwnership

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _active = NO;
        // `source` is only meaningful while `active == YES`. Initialize
        // to `User` so the field has a defined value if some future
        // caller reads it before `-startWithSource:`.
        _source = KYAActivationSourceUser;
    }
    return self;
}

- (void)startWithSource:(KYAActivationSource)source
{
    self.active = YES;
    self.source = source;
}

- (void)terminate
{
    self.active = NO;
    // Reset to `User` so the field doesn't dangle at the last feature
    // trigger's value — mirrors the pre-extraction reset in
    // `KYAAppController -terminateTimerWithReason:`.
    self.source = KYAActivationSourceUser;
}

- (BOOL)terminateIfOwnedBySource:(KYAActivationSource)source
{
    if(self.active == NO) { return NO; }
    if(self.source != source) { return NO; }
    [self terminate];
    return YES;
}

@end
