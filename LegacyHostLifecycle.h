//
//  LegacyHostLifecycle.h
//  Blue Screen Saver
//

#import <ScreenSaver/ScreenSaver.h>

NS_ASSUME_NONNULL_BEGIN

/// Mitigates Sonoma+ legacyScreenSaver host lifecycle bugs (orphaned animation, RAM growth).
@interface LegacyHostLifecycle : NSObject

- (instancetype)initWithSaverView:(ScreenSaverView *)saverView isPreview:(BOOL)isPreview;
- (void)startMonitoring;
- (void)stopMonitoring;

@end

NS_ASSUME_NONNULL_END
