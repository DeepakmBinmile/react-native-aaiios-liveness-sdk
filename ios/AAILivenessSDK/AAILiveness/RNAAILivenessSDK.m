//
//  RNAAILivenessSDK.m
//  Pods
//
//  Created by aaaa zhao on 2020/10/28.
//

#import "RNAAILivenessSDK.h"
@import AAILivenessSDK;

@implementation RNAAILivenessSDK

RCT_EXPORT_MODULE()

- (instancetype)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

RCT_EXPORT_METHOD(init:(NSString *)accessKey secretKey:(NSString *)secretKey market:(NSString *)market)
{
    AAILivenessMarket currMarket = [RNAAILivenessSDK marketWithStr: market];
    [AAILivenessSDK initWithAccessKey:accessKey secretKey: secretKey market: currMarket];
}

RCT_EXPORT_METHOD(initWithMarket:(NSString *)market)
{
    AAILivenessMarket currMarket = [RNAAILivenessSDK marketWithStr: market];
    [AAILivenessSDK initWithMarket: currMarket];
}

RCT_EXPORT_METHOD(initWithMarketAndGlobalService:(NSString *)market isGlobalService:(BOOL)isGlobalService)
{
    AAILivenessMarket currMarket = [RNAAILivenessSDK marketWithStr: market];
    [AAILivenessSDK initWithMarket: currMarket isGlobalService:isGlobalService];
}

RCT_EXPORT_METHOD(configLicenseAndCheck:(NSString *)license callback: (RCTResponseSenderBlock)callback)
{
    NSString *result = [AAILivenessSDK configLicenseAndCheck:license];
    callback(@[result]);
}

RCT_EXPORT_METHOD(configDetectOcclusion:(BOOL)detectOcc)
{
    [AAILivenessSDK configDetectOcclusion:detectOcc];
}

RCT_EXPORT_METHOD(configUserId:(NSString *)userId)
{
    [AAILivenessSDK configUserId:userId];
}

RCT_EXPORT_METHOD(configResultPictureSize:(CGFloat)size)
{
    [AAILivenessSDK configResultPictureSize:size];
}

RCT_EXPORT_METHOD(configActionTimeoutSeconds:(NSInteger)actionTimeout)
{
    [AAILivenessSDK configActionTimeoutSeconds:actionTimeout];
}

RCT_EXPORT_METHOD(sdkVersion:(RCTResponseSenderBlock)callback)
{
    NSString *version = [AAILivenessSDK sdkVersion];
    callback(@[version]);
}

+ (AAILivenessMarket)marketWithStr:(NSString *)marketStr
{
    NSDictionary *map = @{
        @"AAILivenessMarketIndonesia": @(AAILivenessMarketIndonesia),
        @"AAILivenessMarketIndia": @(AAILivenessMarketIndia),
        @"AAILivenessMarketPhilippines": @(AAILivenessMarketPhilippines),
        @"AAILivenessMarketVietnam": @(AAILivenessMarketVietnam),
        @"AAILivenessMarketThailand": @(AAILivenessMarketThailand),
        @"AAILivenessMarketMexico": @(AAILivenessMarketMexico),
        @"AAILivenessMarketMalaysia": @(AAILivenessMarketMalaysia),
        @"AAILivenessMarketPakistan": @(AAILivenessMarketPakistan),
        @"AAILivenessMarketNigeria": @(AAILivenessMarketNigeria),
        @"AAILivenessMarketColombia": @(AAILivenessMarketColombia),
        @"AAILivenessMarketSingapore":@(AAILivenessMarketSingapore)
    };
    return (AAILivenessMarket)([map[marketStr] integerValue]);
}

@end
