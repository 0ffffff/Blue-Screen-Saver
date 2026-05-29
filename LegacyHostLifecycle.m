//
//  LegacyHostLifecycle.m
//  Blue Screen Saver
//

#import "LegacyHostLifecycle.h"

static NSString *const kScreenSaverWillStopNotification = @"com.apple.screensaver.willstop";
static const NSTimeInterval kExitDelaySeconds = 0.25;
static const NSTimeInterval kWindowPollIntervalSeconds = 0.5;
static const NSTimeInterval kDismissedWindowLevelGraceSeconds = 2.0;

@interface LegacyHostLifecycle ()
@property (nonatomic, weak) ScreenSaverView *saverView;
@property (nonatomic, assign) BOOL isPreview;
@property (nonatomic, assign) BOOL isMonitoring;
@property (nonatomic, strong, nullable) NSTimer *windowLevelTimer;
@property (nonatomic, assign) NSTimeInterval dismissedSince;
@property (nonatomic, assign) BOOL hasSeenActiveWindowLevel;
@end

@implementation LegacyHostLifecycle

- (instancetype)initWithSaverView:(ScreenSaverView *)saverView isPreview:(BOOL)isPreview
{
    self = [super init];
    if (self) {
        _saverView = saverView;
        _isPreview = isPreview;
        _dismissedSince = 0;
    }
    return self;
}

- (void)dealloc
{
    [self stopMonitoring];
}

- (void)startMonitoring
{
    if (self.isMonitoring) {
        return;
    }
    self.isMonitoring = YES;

    [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(screenSaverWillStop:)
                                                            name:kScreenSaverWillStopNotification
                                                          object:nil];

    if (!self.isPreview) {
        self.windowLevelTimer = [NSTimer scheduledTimerWithTimeInterval:kWindowPollIntervalSeconds
                                                                 target:self
                                                               selector:@selector(pollWindowLevel:)
                                                               userInfo:nil
                                                                repeats:YES];
    }
}

- (void)stopMonitoring
{
    if (!self.isMonitoring) {
        return;
    }
    self.isMonitoring = NO;

    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    [self.windowLevelTimer invalidate];
    self.windowLevelTimer = nil;
}

- (void)screenSaverWillStop:(NSNotification *)notification
{
    [self handleScreenSaverEndingShouldExit:YES];
}

- (void)pollWindowLevel:(NSTimer *)timer
{
    if (self.isPreview) {
        return;
    }

    NSWindow *window = self.saverView.window;
    if (!window) {
        return;
    }

    // Screen saver windows sit at the screen-saver level while active.
    const NSInteger screenSaverLevel = NSScreenSaverWindowLevel;
    if (window.level >= screenSaverLevel) {
        self.hasSeenActiveWindowLevel = YES;
        self.dismissedSince = 0;
        return;
    }

    if (!self.hasSeenActiveWindowLevel) {
        return;
    }

    NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (self.dismissedSince == 0) {
        self.dismissedSince = now;
        [self handleScreenSaverEndingShouldExit:NO];
        return;
    }

    if (now - self.dismissedSince >= kDismissedWindowLevelGraceSeconds) {
        [self requestProcessExit];
    }
}

- (void)handleScreenSaverEndingShouldExit:(BOOL)shouldExit
{
    [self.saverView stopAnimation];

    if (shouldExit && !self.isPreview) {
        [self requestProcessExit];
    }
}

- (void)requestProcessExit
{
    if (self.isPreview) {
        return;
    }

    [self stopMonitoring];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kExitDelaySeconds * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        exit(0);
    });
}

@end
