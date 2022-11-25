#import "RNAAILivenessViewManager.h"
#import <React/RCTUIManager.h>
#import "RNAAILivenessView.h"

@interface RNAAILivenessViewManager()
@end

@implementation RNAAILivenessViewManager

RCT_EXPORT_MODULE(RNAAILivenessView)

RCT_EXPORT_VIEW_PROPERTY(showHUD, BOOL)
RCT_EXPORT_VIEW_PROPERTY(detectionActions, NSArray)
RCT_EXPORT_VIEW_PROPERTY(language, NSString)
RCT_EXPORT_VIEW_PROPERTY(prepareTimeoutInterval, NSInteger)

- (UIView *)view
{
  return [[RNAAILivenessView alloc] init];
}

RCT_EXPORT_METHOD(graduallySetBrightness:(nonnull NSNumber*)reactTag brightness:(nonnull NSNumber *)brightness)
{
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RNAAILivenessView *view = (RNAAILivenessView *)viewRegistry[reactTag];
        if (!view || ![view isKindOfClass:[RNAAILivenessView class]]) {
            return;
        }
        [view graduallySetBrightness: brightness.floatValue];
    }];
}

RCT_EXPORT_METHOD(graduallyResumeBrightness:(nonnull NSNumber*)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RNAAILivenessView *view = (RNAAILivenessView *)viewRegistry[reactTag];
        if (!view || ![view isKindOfClass:[RNAAILivenessView class]]) {
            return;
        }
        [view graduallyResumeBrightness];
    }];
}

RCT_EXPORT_METHOD(rnViewDidDisappear:(nonnull NSNumber*)reactTag)
{
    [self.bridge.uiManager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RNAAILivenessView *view = (RNAAILivenessView *)viewRegistry[reactTag];
        if (!view || ![view isKindOfClass:[RNAAILivenessView class]]) {
            return;
        }
        [view rnViewDidDisappear];
    }];
}

@end
