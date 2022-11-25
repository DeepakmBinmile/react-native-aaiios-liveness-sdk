//
//  RNAAILivenessSDKEvent.h
//  Pods
//
//  Created by aaaa zhao on 2020/10/29.
//

#import <Foundation/Foundation.h>
#import <React/RCTEventEmitter.h>

NS_ASSUME_NONNULL_BEGIN

@interface RNAAILivenessSDKEvent : RCTEventEmitter <RCTBridgeModule>

+ (void)postNotiToReactNative:(NSString *)name body:(NSDictionary * _Nullable)body;

@end

NS_ASSUME_NONNULL_END
