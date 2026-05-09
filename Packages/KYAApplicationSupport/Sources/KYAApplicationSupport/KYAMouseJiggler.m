//
//  KYAMouseJiggler.m
//  KYAApplicationSupport
//

#import <KYAApplicationSupport/KYAMouseJiggler.h>
#import <KYACommon/KYACommon.h>

@interface KYAMouseJiggler ()
@property (nonatomic, nullable) NSTimer *tickTimer;
@property (nonatomic, readwrite, getter=isRunning) BOOL running;
@end

@implementation KYAMouseJiggler

- (instancetype)init
{
    self = [super init];
    if(self) { _interval = 60.0; }
    return self;
}

- (void)dealloc
{
    [_tickTimer invalidate];
}

- (void)start
{
    if(self.running) { return; }
    self.running = YES;
    [self nudgeOnce];

    AutoWeak weakSelf = self;
    Auto timer = [NSTimer scheduledTimerWithTimeInterval:self.interval
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull t) {
        [weakSelf nudgeOnce];
    }];
    timer.tolerance = MAX(1.0, self.interval * 0.05);
    self.tickTimer = timer;
}

- (void)stop
{
    [self.tickTimer invalidate];
    self.tickTimer = nil;
    self.running = NO;
}

- (void)nudgeOnce
{
    // Read the current pointer location and post a +1px / -1px sequence.
    // Total visible drift is zero; the system idle counter resets on the
    // first event regardless of magnitude.
    CGEventRef peek = CGEventCreate(NULL);
    if(peek == NULL) { return; }
    CGPoint here = CGEventGetLocation(peek);
    CFRelease(peek);

    CGPoint forward = CGPointMake(here.x + 1.0, here.y);
    CGEventRef e1 = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, forward, kCGMouseButtonLeft);
    if(e1 != NULL)
    {
        CGEventPost(kCGHIDEventTap, e1);
        CFRelease(e1);
    }

    CGEventRef e2 = CGEventCreateMouseEvent(NULL, kCGEventMouseMoved, here, kCGMouseButtonLeft);
    if(e2 != NULL)
    {
        CGEventPost(kCGHIDEventTap, e2);
        CFRelease(e2);
    }
}

@end
