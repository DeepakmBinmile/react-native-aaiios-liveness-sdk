//
//  RNAAILivenessView.h
//  Pods
//
//  Created by aaaa zhao on 2020/10/27.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNAAILivenessView : UIView

@property (nonatomic) BOOL showHUD;

@property (nonatomic, copy) NSArray<NSString *> *detectionActions;

/// Specify which language to use for the SDK. If this value is not set,
/// the system language will be used by default. If the system language is not supported,
/// English will be used.
///
/// The languages currently supported by sdk are as follows:
/// \code
/// "en" "id"  "vi"  "zh-Hans"  "th"  "es"  "ms" "hi"   
@property(nonatomic, copy, nullable) NSString *language;

/// Set the timeout for prepare stage, default is 10s.
///
/// This value refers to the time from when the sdk page is displayed to when the motion detection is ready.
/// For example, after the sdk page is presented, if the user does not hold the phone upright or put the face in the detection area,
/// and continues in this state for a certain period of time, then the `onDetectionFailed` will be called,
/// and the value of the "errorCode" is "fail_reason_prepare_timeout".
@property(nonatomic) NSInteger prepareTimeoutInterval;

// Should be called when view appear
- (void)graduallySetBrightness:(CGFloat)brightness;

// Should be called when view disappear
- (void)graduallyResumeBrightness;

// Reset view state
- (void)rnViewDidDisappear;

@end

NS_ASSUME_NONNULL_END
