//
//  RNAAILivenessSDKEvent.m
//  Pods
//
//  Created by aaaa zhao on 2020/10/29.
//

#import "RNAAILivenessSDKEvent.h"

@interface RNAAILivenessSDKEvent()
{
    bool _hasListeners;
}
@end
@implementation RNAAILivenessSDKEvent

RCT_EXPORT_MODULE();

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"RNAAILivenessSDKEvent"];
}

- (void)startObserving
{
    _hasListeners = YES;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(emitEventInternal:) name:@"RNAAILivenessSDKEventNotify" object:nil];
    });
}

- (void)stopObserving
{
    _hasListeners = NO;
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    });
}

- (void)emitEventInternal:(NSNotification *)notification
{
    [self sendEventWithName:@"RNAAILivenessSDKEvent" body:notification.object];
}

+ (void)postNotiToReactNative:(NSString *)name body:(NSDictionary * _Nullable)body
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        dic[@"name"] = name;
        if (body) {
            dic[@"body"] = body;
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RNAAILivenessSDKEventNotify" object:dic];
    });
}

@end
