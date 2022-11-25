//
//  RNAAILivenessView.m
//  Pods
//
//  Created by aaaa zhao on 2020/10/27.
//

#import "RNAAILivenessView.h"
@import AAILivenessSDK;
#import "AAIHUD.h"
#import "AAILivenessUtil.h"
#import <AVFoundation/AVFoundation.h>
#import "RNAAILivenessSDKEvent.h"

@interface RNAAILivenessView()<AAILivenessWrapDelegate>
{
    UIButton *_backBtn;
    UILabel *_stateLabel;
    UIImageView *_stateImgView;
    //Voice
    UIButton *_voiceBtn;
    //Time label
    UILabel *_timeLabel;
    CGRect _roundViewFrame;
    
    NSString *_pre_key;
    
    BOOL _isReady;
    BOOL _isRequestingAuth;
    BOOL _requestAuthSucceed;
}
@property(nonatomic, strong) AAILivenessWrapView *wrapView;
@property(nonatomic) BOOL isRequestingAuth;
@property(nonatomic) BOOL requestAuthSucceed;
@property(nonatomic) BOOL requestAuthComplete;
@property(nonatomic) BOOL requestAuthCached;
@property(nonatomic) BOOL hasPortraitDirection;
@property(nonatomic) AAILivenessUtil *util;

@property(nonatomic) NSTimeInterval prepareStartTime;
@property(nonatomic) NSTimeInterval authRequestCostTime;
@property(nonatomic) AAITimerWrapper *prepareStageTimer;
@end

@implementation RNAAILivenessView
@synthesize isRequestingAuth = _isRequestingAuth;
@synthesize requestAuthSucceed = _requestAuthSucceed;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _prepareTimeoutInterval = 10;
        [self rnViewDidLoad];
    }
    return self;
}

# pragma mark - Property
- (void)setDetectionActions:(NSArray<NSString *> *)detectionActions
{
    if (detectionActions != nil && detectionActions.count > 0) {
        _detectionActions = [detectionActions copy];
        if (_wrapView != nil) {
            NSMutableArray *tmpArray = [[NSMutableArray alloc] init];
            for (NSString *action in _detectionActions) {
                if ([action isEqualToString:@"AAIDetectionTypeMouth"]) {
                    [tmpArray addObject:@(AAIDetectionTypeMouth)];
                } else if ([action isEqualToString:@"AAIDetectionTypePosYaw"]) {
                    [tmpArray addObject:@(AAIDetectionTypePosYaw)];
                } else if ([action isEqualToString:@"AAIDetectionTypeBlink"]) {
                    [tmpArray addObject:@(AAIDetectionTypeBlink)];
                }
            }
            _wrapView.detectionActions = tmpArray;
        }
    } else {
        _detectionActions = nil;
    }
}

# pragma mark - Style
- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.wrapView.backgroundColor = backgroundColor;
}

# pragma mark - UI

- (void)rnViewDidLoad
{
    _pre_key = nil;
    _isReady = NO;
    _isRequestingAuth = NO;
    _requestAuthSucceed = NO;
    _requestAuthComplete = NO;
    _requestAuthCached = NO;
    _showHUD = YES;
    
    _util = [[AAILivenessUtil alloc] init];
    
    // Config model file path
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"AAIModel.bundle" ofType:NULL];
    if (modelPath == NULL) {
        modelPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"AAIModel.bundle" ofType:NULL];
    }
    if (modelPath == NULL) {
        NSLog(@"ERROR: AAIModel.bundle Not Found!");
        return;
    }
    [AAILivenessSDK configModelBundlePath: modelPath];
    
    UIView *sv = self;
    AAILivenessWrapView *wrapView = [[AAILivenessWrapView alloc] init];
    [sv addSubview:wrapView];
    /*
    //Custom UI
    wrapView.backgroundColor = [UIColor grayColor];
    wrapView.roundBorderView.layer.borderColor = [UIColor redColor].CGColor;
    wrapView.roundBorderView.layer.borderWidth = 2;
      
    //Custom corner radius and the shape of the preview area
    CGFloat cornerRadius = 20;
    wrapView.roundBorderView.layer.cornerRadius = cornerRadius;
    wrapView.configAvatarPreviewPath = ^(CGSize avatarPreviewSize, UIBezierPath * _Nonnull originRectPath) {
        UIBezierPath *squarePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, avatarPreviewSize.width, avatarPreviewSize.width) cornerRadius:cornerRadius];
        [originRectPath appendPath: [squarePath bezierPathByReversingPath]];
    };
     
    //Custom preview area margin top
    wrapView.configAvatarPreviewMarginTop = ^CGFloat(CGRect wrapViewFrame) {
        return 64;
    };
      
    //Custom preview area width
    wrapView.configAvatarPreviewWidth = ^CGFloat(CGRect wrapViewFrame) {
        return 300;
    };
     */
    /*
    //You can custom detectionActions
    wrapView.detectionActions = @[@(AAIDetectionTypeMouth), @(AAIDetectionTypePosYaw), @(AAIDetectionTypeBlink)];
     */
    wrapView.wrapDelegate = self;
    _wrapView = wrapView;
    
    //Detect state label
    UILabel *stateLabel = [[UILabel alloc] init];
    stateLabel.font = [UIFont systemFontOfSize:16];
    stateLabel.textColor = [UIColor blackColor];
    stateLabel.numberOfLines = 0;
    stateLabel.textAlignment = NSTextAlignmentCenter;
    [sv addSubview:stateLabel];
    _stateLabel = stateLabel;
    
    //Action status imageView
    UIImageView *stateImgView = [[UIImageView alloc] init];
    stateImgView.contentMode = UIViewContentModeScaleAspectFit;
    [sv addSubview:stateImgView];
    _stateImgView = stateImgView;
    
    //Voice switch button
    UIButton *voiceBtn = [[UIButton alloc] init];
    [voiceBtn setImage:[AAILivenessUtil imgWithName:@"liveness_open_voice@2x.png"] forState:UIControlStateNormal];
    [voiceBtn setImage:[AAILivenessUtil imgWithName:@"liveness_close_voice@2x.png"] forState:UIControlStateSelected];
    [sv addSubview:voiceBtn];
    [voiceBtn addTarget:self action:@selector(tapVoiceBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    
    if ([AAILivenessUtil isSilent]) {
        voiceBtn.selected = YES;
    }
    
    _voiceBtn = voiceBtn;
    
    //Timeout interval label
    _timeLabel = [[UILabel alloc] init];
    _timeLabel.font = [UIFont systemFontOfSize:14];
    _timeLabel.textColor = [UIColor colorWithRed:(0x36/255.f) green:(0x36/255.f) blue:(0x36/255.f) alpha:1];
    _timeLabel.text = [NSString stringWithFormat:@"%d S", aai_timeout_interval];
    _timeLabel.textAlignment = NSTextAlignmentCenter;
    [sv addSubview:_timeLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(restartDetection) name:@"kAAIRestart" object:nil];
    [[AVAudioSession sharedInstance] addObserver:self forKeyPath:@"outputVolume" options:NSKeyValueObservingOptionNew context:nil];
    
    [_util saveCurrBrightness];
    
    _timeLabel.hidden = YES;
    _voiceBtn.hidden = YES;
    
    [self startPrepareStageTimer];
    [self startCamera];
}

- (void)rnViewDidLayoutSubviews
{
    // Do not modify begin
    CGRect rect = self.frame;
    _wrapView.frame = rect;
    [_wrapView setNeedsLayout];
    [_wrapView layoutIfNeeded];
    
    CGSize size = rect.size;
    CGRect tmpFrame = _wrapView.roundBorderView.frame;
    _roundViewFrame = [_wrapView.roundBorderView convertRect:tmpFrame toView:self];
    // Do not modify end
    
    //top
    CGFloat top = 0, marginLeft = 20, marginTop = 20;
    if (@available(iOS 11, *)) {
        top = self.safeAreaInsets.top;
    } else {
        top = [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    
    //State image
    CGFloat stateImgViewWidth = 120;
    _stateImgView.frame = CGRectMake((size.width-stateImgViewWidth)/2, CGRectGetMaxY(_roundViewFrame) + 80, stateImgViewWidth, stateImgViewWidth);
    
    //Time label
    CGFloat timeLabelCenterY = 0;
    CGSize timeLabelSize = CGSizeMake(40, 24);
    if (_backBtn) {
        timeLabelCenterY = _backBtn.center.y;
    } else {
        timeLabelCenterY = top + marginTop + timeLabelSize.height/2;
    }
    _timeLabel.bounds = CGRectMake(0, 0, timeLabelSize.width, timeLabelSize.height);
    _timeLabel.center = CGPointMake(size.width - marginLeft - 20, timeLabelCenterY);
    _timeLabel.layer.cornerRadius = 12;
    _timeLabel.layer.borderWidth = 1;
    _timeLabel.layer.borderColor = _timeLabel.textColor.CGColor;
    
    _voiceBtn.bounds = CGRectMake(0, 0, 32, 32);
    _voiceBtn.center = CGPointMake(_timeLabel.center.x, CGRectGetMaxY(_timeLabel.frame)+20);
}

- (void)graduallySetBrightness:(CGFloat)brightness
{
    [_util graduallySetBrightness:brightness];
}

- (void)graduallyResumeBrightness
{
    [_util graduallyResumeBrightness];
}

- (void)rnViewDidDisappear
{
    [self resetViewState];
    _wrapView.roundBorderView.backgroundColor = [UIColor whiteColor];
    [self clearListener];
}

- (void)updateStateLabel:(NSString *)state
{
    CGRect frame = _roundViewFrame;
    CGFloat w = frame.size.width;
    CGFloat marginTop = 40;
    if (state) {
        _stateLabel.text = state;
        CGSize size = [_stateLabel sizeThatFits:CGSizeMake(w, 1000)];
        _stateLabel.frame = CGRectMake(frame.origin.x, CGRectGetMaxY(frame) + marginTop, w, size.height);
    } else {
        _stateLabel.text = nil;
        _stateLabel.frame = CGRectMake(frame.origin.x, CGRectGetMaxY(frame) + marginTop, frame.size.width, 30);
    }
}

- (void)showImgWithType:(AAIDetectionType)detectionType
{
    switch (detectionType) {
        case AAIDetectionTypeBlink:
        case AAIDetectionTypeMouth:
        case AAIDetectionTypePosYaw: {
            [_stateImgView stopAnimating];
            NSArray *array = [AAILivenessUtil stateImgWithType:detectionType];
            _stateImgView.animationImages = array;
            _stateImgView.animationDuration = array.count * 1/5.f;
            [_stateImgView startAnimating];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Network

- (BOOL)isRequestingAuth
{
    return _isRequestingAuth;
}

- (BOOL)requestAuthSucceed
{
    return _requestAuthSucceed;
}

#pragma mark - UserAction

- (void)startCamera
{
    __weak typeof(self) weakSelf = self;
    [_wrapView checkCameraPermissionWithCompletionBlk:^(BOOL authed) {
        if (!weakSelf) return;
        
        //Alert no permission
        NSString *state = [AAILivenessUtil localStrForKey:@"no_camera_permission" lprojName:weakSelf.language];
        if (weakSelf.showHUD) {
            [AAIHUD showMsg:state onView:weakSelf duration:1.5];
        }
        
        // detection failed callback
        NSDictionary *errorInfo = @{@"key": @"no_camera_permission", @"message": state, @"authed": @(authed)};
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onCameraPermission" body:errorInfo];
    }];
}

- (void)requestAuth
{
    _isRequestingAuth = YES;
    _isReady = NO;
    _timeLabel.hidden = YES;
    
    __weak typeof(self) weakSelf = self;
    if (self.showHUD) {
        [AAIHUD showWaitWithMsg:[AAILivenessUtil localStrForKey:@"auth_check" lprojName:_language] onView:self];
    }
    
    // begin request callback
    [RNAAILivenessSDKEvent postNotiToReactNative:@"livenessViewBeginRequest" body:@{}];
    
    NSTimeInterval authStartTime = [[NSDate date] timeIntervalSince1970];
    [_wrapView startAuthWithCompletionBlk:^(NSError * _Nonnull error) {
        __strong RNAAILivenessView *strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.isRequestingAuth = NO;
            strongSelf.requestAuthComplete = YES;
            strongSelf.authRequestCostTime = [[NSDate date] timeIntervalSince1970] - authStartTime;
            
            // end request callback
            [RNAAILivenessSDKEvent postNotiToReactNative:@"livenessViewEndRequest" body:@{}];
            
            if (error) {
                strongSelf.requestAuthSucceed = NO;
                [strongSelf.prepareStageTimer invalidate];
                
                if (strongSelf.showHUD) {
                    [AAIHUD dismissHUDOnView:strongSelf afterDelay:0];
                }
                
                // error callback
                NSString *transactionId = @"";
                if (error.userInfo) {
                    transactionId = error.userInfo[@"transactionId"];
                    if (!transactionId) {
                        transactionId = @"";
                    }
                }
                NSDictionary *errorInfo = @{@"message": error.localizedDescription, @"code": @(error.code), @"transactionId": transactionId};
                [RNAAILivenessSDKEvent postNotiToReactNative:@"onLivenessViewRequestFailed" body:errorInfo];
            } else {
                strongSelf.requestAuthCached = YES;
                strongSelf.requestAuthSucceed = YES;
                if (strongSelf.showHUD) {
                    [AAIHUD dismissHUDOnView:strongSelf afterDelay:0];
                }
            }
        }
    }];
}

- (void)tapVoiceBtnAction:(UIButton *)btn
{
    btn.selected = !btn.selected;
    if (btn.selected) {
        //Close
        [_util configVolume:0];
    } else {
        //Open
        [_util configVolume:0.5];
    }
}

- (void)resetViewState
{
    if (_stateLabel) {
        _stateLabel.text = nil;
    }
    _stateImgView.animationImages = nil;
    _isReady = NO;
    _timeLabel.hidden = YES;
    _voiceBtn.hidden = YES;
}

- (void)restartDetection
{
    [self resetViewState];
    _wrapView.roundBorderView.backgroundColor = [UIColor whiteColor];
    _hasPortraitDirection = NO;
    _requestAuthComplete = NO;
    
    // Stop old timer and start a new timer
    [self startPrepareStageTimer];
    [self startCamera];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self->_wrapView.roundBorderView.backgroundColor = [UIColor clearColor];
    });
}

- (void)startPrepareStageTimer
{
    [_prepareStageTimer invalidate];
    _prepareStartTime = [[NSDate date] timeIntervalSince1970];
    
    __weak typeof(self) weakSelf = self;
    _prepareStageTimer = [AAITimerWrapper scheduledTimerWithTimeInterval:1 repeats:YES execBlock:^(AAITimerWrapper * _Nonnull timerWrapper) {
        [weakSelf prepareStageCountDown];
    }];
}

- (void)prepareStageCountDown
{
    if (!_isReady) {
        NSTimeInterval costTime = [[NSDate date] timeIntervalSince1970] - _prepareStartTime;
        if (costTime >= _prepareTimeoutInterval) {
            if (_isRequestingAuth) return;

            if (_requestAuthComplete) {
                if (costTime - _authRequestCostTime >= _prepareTimeoutInterval) {
                    [self.prepareStageTimer invalidate];
                    [self.wrapView stopRunning];
                    
                    NSString *key = @"fail_reason_prepare_timeout";
                    NSString *state = [AAILivenessUtil localStrForKey:key lprojName:self.language];
                    NSDictionary *errorInfo = @{@"key": key, @"message": state};
                    [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionFailed" body:errorInfo];
                }
                return;
            }
            // Other case: Auth request not start yet
            [self.prepareStageTimer invalidate];
            [self.wrapView stopRunning];
            
            NSString *key = @"fail_reason_prepare_timeout";
            NSString *state = [AAILivenessUtil localStrForKey:key lprojName:self.language];
            NSDictionary *errorInfo = @{@"key": key, @"message": state};
            [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionFailed" body:errorInfo];
        }
    } else {
        [self.prepareStageTimer invalidate];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"outputVolume"]) {
        float volume = [change[NSKeyValueChangeNewKey] floatValue];
        [_util configPlayerVolume:volume];
        if (volume == 0) {
            if (_voiceBtn.selected == NO) {
                _voiceBtn.selected = YES;
            }
        } else {
            if (_voiceBtn.selected == YES) {
                _voiceBtn.selected = NO;
            }
        }
    }
}

#pragma mark - WrapViewDelegate

- (void)onDetectionReady:(AAIDetectionType)detectionType
{
    _isReady = YES;
    _timeLabel.hidden = NO;
    
    [_prepareStageTimer invalidate];
    _prepareStageTimer = nil;
    
    NSString *key = nil;
    if (detectionType == AAIDetectionTypeBlink) {
        key = @"pls_blink";
        [_util playAudio:@"action_blink.mp3"];
    } else if (detectionType == AAIDetectionTypeMouth) {
        key = @"pls_open_mouth";
        [_util playAudio:@"action_open_mouth.mp3"];
    } else if (detectionType == AAIDetectionTypePosYaw) {
        key = @"pls_turn_head";
        [_util playAudio:@"action_turn_head.mp3"];
    }
    
    if (key) {
        NSString *state = [AAILivenessUtil localStrForKey:key lprojName:_language];
        _stateLabel.text = state;
        [self showImgWithType:detectionType];
        // detection ready callback
        NSDictionary *info = @{@"key": key, @"message": state};
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionReady" body:info];
    }
}

- (void)onDetectionFailed:(AAIDetectionResult)detectionResult forDetectionType:(AAIDetectionType)detectionType
{
    [_util playAudio:@"detection_failed.mp3"];
    [AAILocalizationUtil stopMonitor];
    
    //Reset
    _pre_key = nil;
    
    NSString *key = nil;
    switch (detectionResult) {
        case AAIDetectionResultTimeout:
            key = @"fail_reason_timeout";
            break;
        case AAIDetectionResultErrorMutipleFaces:
            key = @"fail_reason_muti_face";
            break;
        case AAIDetectionResultErrorFaceMissing: {
            switch (detectionType) {
                case AAIDetectionTypeBlink:
                case AAIDetectionTypeMouth:
                    key = @"fail_reason_facemiss_blink_mouth";
                    break;
                case AAIDetectionTypePosYaw:
                    key = @"fail_reason_facemiss_pos_yaw";
                    break;
                default:
                    break;
            }
            break;
        }
        case AAIDetectionResultErrorMuchMotion:
            key = @"fail_reason_much_action";
            break;
        default:
            break;
    }
    
    //Show result page
    if (key) {
        NSString *state = [AAILivenessUtil localStrForKey:key lprojName:_language];
        [self updateStateLabel:state];
        
        [_stateImgView stopAnimating];
        
        // detection failed callback
        NSDictionary *errorInfo = @{@"key": key, @"message": state};
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionFailed" body:errorInfo];
    }
}

- (BOOL)shouldDetect
{
    if (_hasPortraitDirection == NO) {
        _hasPortraitDirection = [AAILocalizationUtil isPortraitDirection];
        if (_hasPortraitDirection) {
            if (_requestAuthCached == NO && _isRequestingAuth == NO && _requestAuthComplete == NO) {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (_requestAuthCached == NO && _isRequestingAuth == NO && _requestAuthComplete == NO) {
                        [self requestAuth];
                    }
                });
            }
            return _requestAuthCached;
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self->_isReady == NO) {
                    self->_timeLabel.hidden = YES;
                    self-> _voiceBtn.hidden = YES;
                    self->_stateImgView.animationImages = nil;
                }
                
                NSString *state = [AAILivenessUtil localStrForKey:@"pls_hold_phone_v" lprojName:self.language];
                [self updateStateLabel:state];
                
                if (self->_pre_key == nil) {
                    self->_pre_key = @"pls_hold_phone_v";
                    
                    // frame detected call back
                    NSDictionary *info = @{@"key": @"pls_hold_phone_v", @"state": state};
                    [RNAAILivenessSDKEvent postNotiToReactNative:@"onFrameDetected" body:info];
                }
            });
        }
        
        return NO;
    } else {
        if (_requestAuthCached == NO && _isRequestingAuth == NO  && _requestAuthComplete == NO) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (_requestAuthCached == NO && _isRequestingAuth == NO && _requestAuthComplete == NO) {
                    [self updateStateLabel:nil];
                    [self requestAuth];
                }
            });
        }
        return _requestAuthCached;
    }
    return YES;
}

- (void)onFrameDetected:(AAIDetectionResult)result status:(AAIActionStatus)status forDetectionType:(AAIDetectionType)detectionType
{
    NSString *key = nil;
    if (_isReady == NO && [AAILocalizationUtil isPortraitDirection] == NO) {
        key = @"pls_hold_phone_v";
    } else {
        switch (result) {
            case AAIDetectionResultFaceMissing:
                key = @"no_face";
                break;
            case AAIDetectionResultFaceLarge:
                key = @"move_further";
                break;
            case AAIDetectionResultFaceSmall:
                key = @"move_closer";
                break;
            case AAIDetectionResultFaceNotCenter:
                key = @"move_center";
                break;
            case AAIDetectionResultFaceNotFrontal:
                key = @"frontal";
                break;
            case AAIDetectionResultFaceNotStill:
                key = @"stay_still";
                break;
            case AAIDetectionResultFaceInAction: {
                if (detectionType == AAIDetectionTypeBlink) {
                    key = @"pls_blink";
                } else if (detectionType == AAIDetectionTypePosYaw) {
                    key = @"pls_turn_head";
                } else if (detectionType == AAIDetectionTypeMouth) {
                    key = @"pls_open_mouth";
                }
            }
                break;
            case AAIDetectionResultWarnMouthOcclusion: {
                key = @"face_occ";
                break;
            }
            default:
                break;
        }
    }
    
    if (key) {
        if ([key isEqualToString:_pre_key]) {
            return;
        }
        _pre_key = key;
        
        NSString *state = [AAILivenessUtil localStrForKey:key lprojName:_language];
        [self updateStateLabel:state];
        
        // frame detected call back
        NSDictionary *info = @{@"key": key, @"state": state};
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onFrameDetected" body:info];
    }
}

- (void)onDetectionTypeChanged:(AAIDetectionType)toDetectionType
{
    NSString *key = nil;
    if (toDetectionType == AAIDetectionTypeBlink) {
        key = @"pls_blink";
        [_util playAudio:@"action_blink.mp3"];
    } else if (toDetectionType == AAIDetectionTypeMouth) {
        key = @"pls_open_mouth";
        [_util playAudio:@"action_open_mouth.mp3"];
    } else if (toDetectionType == AAIDetectionTypePosYaw) {
        key = @"pls_turn_head";
        [_util playAudio:@"action_turn_head.mp3"];
    }
    
    if (key) {
        NSString *state = [AAILivenessUtil localStrForKey:key lprojName:_language];
        [self updateStateLabel:state];
        [self showImgWithType:toDetectionType];
        
        // detection type changed callback
        NSDictionary *info = @{@"key": key, @"state": state};
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionTypeChanged" body:info];
    }
}

- (void)onDetectionComplete:(AAILivenessResult *)resultInfo
{
    [_util playAudio:@"detection_success.mp3"];
    [AAILocalizationUtil stopMonitor];
    NSString *state = [AAILivenessUtil localStrForKey:@"detection_success" lprojName:_language];
    [self updateStateLabel:state];
    [_stateImgView stopAnimating];
    _pre_key = nil;
    
    NSData *imgData = UIImageJPEGRepresentation(resultInfo.img, 1.0f);
    NSString *base64ImgStr = [imgData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    NSDictionary *successInfo = @{
            @"livenessId": resultInfo.livenessId,
            @"img": base64ImgStr,
            @"transactionId": (resultInfo.transactionId == nil ? @"":resultInfo.transactionId)
        };
    [RNAAILivenessSDKEvent postNotiToReactNative:@"onDetectionComplete" body:successInfo];
}

- (void)onDetectionRemainingTime:(NSTimeInterval)remainingTime forDetectionType:(AAIDetectionType)detectionType
{
    if (_isReady) {
        _timeLabel.hidden = NO;
        _voiceBtn.hidden = NO;
        _timeLabel.text = [NSString stringWithFormat:@"%.f S", remainingTime];
    }
}

- (void)livenessViewBeginRequest:(AAILivenessWrapView * _Nonnull)param
{
    if (self.showHUD) {
        [AAIHUD showWaitWithMsg:[AAILivenessUtil localStrForKey:@"auth_check" lprojName:_language] onView:self];
    }
    
    [self updateStateLabel:nil];
    [_stateImgView stopAnimating];
    
    // begin request callback
    [RNAAILivenessSDKEvent postNotiToReactNative:@"livenessViewBeginRequest" body:@{}];
}

- (void)livenessView:(AAILivenessWrapView *)param endRequest:(NSError * _Nullable)error
{
    if (self.showHUD) {
        [AAIHUD dismissHUDOnView:self afterDelay:0];
    }
    
    // end request callback
    NSDictionary *errorInfo = nil;
    if (error) {
        NSString *transactionId = @"";
        if (error.userInfo) {
            transactionId = error.userInfo[@"transactionId"];
            if (!transactionId) {
                transactionId = @"";
            }
        }

        errorInfo = @{@"message": error.localizedDescription, @"code": @(error.code), @"transactionId": transactionId};
    } else {
        errorInfo = @{};
    }
    [RNAAILivenessSDKEvent postNotiToReactNative:@"livenessViewEndRequest" body:errorInfo];
    
    // error callback
    if (error) {
        [RNAAILivenessSDKEvent postNotiToReactNative:@"onLivenessViewRequestFailed" body:errorInfo];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self rnViewDidLayoutSubviews];
}

- (void)clearListener
{
    //If `rnViewDidLoad` method not called, we do nothing.
    if (_util != nil) {
        [AAILocalizationUtil stopMonitor];
        [_util removeVolumeView];
        [_prepareStageTimer invalidate];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kAAIRestart" object:nil];
        [[AVAudioSession sharedInstance] removeObserver:self forKeyPath:@"outputVolume"];
    }
}

@end
