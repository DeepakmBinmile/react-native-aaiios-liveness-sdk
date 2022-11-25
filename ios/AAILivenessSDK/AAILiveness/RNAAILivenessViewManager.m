#import "RNAAILivenessViewManager.h"
#import <React/RCTUIManager.h>
#import "RNAAILivenessView.h"
#import "RNAAILivenessSDKEvent.h"

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
    RNAAILivenessView *livenessView = [[RNAAILivenessView alloc] init];
    
    livenessView.cameraPermissionDeniedBlk = ^(RNAAILivenessView * _Nonnull rawVC) {
        NSString *state = [AAILivenessUtil localStrForKey:@"no_camera_permission" lprojName:rawVC.language];
        NSDictionary *errorInfo = @{@"key": @"no_camera_permission", @"message": state, @"authed": @(NO)};
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onCameraPermission" body:errorInfo];
    };
    
    livenessView.beginRequestBlk = ^(RNAAILivenessView * _Nonnull rawVC) {
        [RNAAILivenessSDKEvent postNotiToReactNative:@"livenessViewBeginRequest" body:@{}];
    };
    livenessView.endRequestBlk = ^(RNAAILivenessView * _Nonnull rawVC, NSDictionary * _Nullable errorInfo) {
        [RNAAILivenessSDKEvent postNotiToReactNative:@"livenessViewEndRequest" body:@{}];
        
        if (errorInfo) {
            [RNAAILivenessSDKEvent postNotiToReactNative:@"onLivenessViewRequestFailed" body:errorInfo];
        }
    };
    
    livenessView.detectionReadyBlk = ^(RNAAILivenessView * _Nonnull rawVC, AAIDetectionType detectionType, NSDictionary * _Nonnull info) {
        NSString *message = info[@"state"];
        NSDictionary *dict = @{@"key": info[@"key"], @"message": message, @"state": message};
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionReady" body:dict];
    };
    
    livenessView.detectionFailedBlk = ^(RNAAILivenessView * _Nonnull rawVC, NSDictionary * _Nonnull errorInfo) {
        NSString *key = errorInfo[@"key"];
        if (key) {
            NSString *message = errorInfo[@"state"];
            NSDictionary *dict = @{@"key": key, @"message": message, @"state": message};
            [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionFailed" body:dict];
        }
    };
    
    livenessView.frameDetectedBlk = ^(RNAAILivenessView * _Nonnull rawVC, AAIDetectionType detectionType, AAIActionStatus status, AAIDetectionResult result, NSDictionary * _Nonnull info) {
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onFrameDetected" body:info];
    };
    
    livenessView.detectionTypeChangedBlk = ^(RNAAILivenessView * _Nonnull rawVC, AAIDetectionType toDetectionType, NSDictionary * _Nonnull info) {
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionTypeChanged" body:info];
    };
    
    livenessView.detectionSuccessBlk = ^(RNAAILivenessView * _Nonnull rawVC, AAILivenessResult * _Nonnull result) {
        NSData *imgData = UIImageJPEGRepresentation(result.img, 1.0f);
        NSString *base64ImgStr = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        NSDictionary *successInfo = @{
                @"livenessId": result.livenessId,
                @"img": base64ImgStr,
                @"transactionId": (result.transactionId == nil ? @"" : result.transactionId)
            };
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionComplete" body:successInfo];
    };
    
    return livenessView;
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
