//
//  RCTXfei.h
//  RCTXfei
//
//  Created by Jack Zhang on 17/3/16.
//  Copyright © 2017. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <React/RCTBridgeModule.h>
#import <React/RCTEventEmitter.h>
#import "IFlyMSC/IFlyMSC.h"


@interface RCTXfei : RCTEventEmitter<RCTBridgeModule, IFlySpeechEvaluatorDelegate>;

@property (nonatomic, strong) IFlySpeechEvaluator *iFlySpeechEvaluator;

@property (nonatomic, assign) BOOL isSessionResultAppear;
@property (nonatomic, assign) BOOL isSessionEnd;

@property (nonatomic, assign) BOOL isValidInput;
@property (nonatomic, assign) BOOL isDidset;

@property (nonatomic,assign) BOOL isBeginOfSpeech; //是否已经返回BeginOfSpeech回调

//初始化
+ (void) crateMyUtility :(NSString *) id;
- (void) callback: (NSString *) type msg:(NSString *)msg data:(NSString *)data;

@end

