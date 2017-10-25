//
//  RCTXfei.m
//  RCTXfei
//
//  Created by Jack Zhang on 17/10/18.
//  Copyright © 2017年. All rights reserved.
//

#import "Xfei.h"
#import "../Definition.h"
#import "../pcmutil/PcmUtil.h"
#import "iflyMSC/IFlySpeechRecognizerDelegate.h"
#import "iflyMSC/IFlySpeechRecognizer.h"
#import "iflyMSC/IFlySpeechConstant.h"
#import "ISEResult.h"
#import "ISEResultXmlParser.h"
#import "ISEParams.h"
#import "ISEResult.h"
#import "ISEResultXmlParser.h"


@implementation RCTXfei

RCT_EXPORT_MODULE(XfeiModule);

/*
 事件回调
 */
- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onISECallback"];
}

/*
 设置参数
 */
RCT_EXPORT_METHOD(setParameter :(NSString *)key value:(NSString *)value){
    NSLog(@"%s[IN]",__func__);
    
    [self initSpeechEvaluator];
    [self.iFlySpeechEvaluator setParameter:value forKey:key];
    
    NSLog(@"%s[OUT]",__func__);
}

/*
 开始录音
 */
RCT_EXPORT_METHOD(startRecord: (NSString *)evalPaper category:(NSString *)category){
    NSLog(@"%s[IN]",__func__);
    
    [self initSpeechEvaluator];
    [self setParams];
    [self.iFlySpeechEvaluator setParameter:category forKey:[IFlySpeechConstant ISE_CATEGORY]];
    [self.iFlySpeechEvaluator setParameter:@"complete" forKey:[IFlySpeechConstant ISE_RESULT_LEVEL]];

    self.isSessionResultAppear=NO;
    self.isSessionEnd=YES;
    
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    
    NSLog(@"text encoding:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]]);
    NSLog(@"language:%@",[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]]);
    
    BOOL isUTF8 = [[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant TEXT_ENCODING]] isEqualToString:@"utf-8"];
    BOOL isZhCN = [[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant LANGUAGE]] isEqualToString:@"zh-cn"];
    
    BOOL needAddTextBom = isUTF8&&isZhCN;
    NSMutableData *buffer = nil;
    if(needAddTextBom){
        if(evalPaper && [evalPaper length]>0){
            Byte bomHeader[] = { 0xEF, 0xBB, 0xBF };
            buffer = [NSMutableData dataWithBytes:bomHeader length:sizeof(bomHeader)];
            [buffer appendData:[evalPaper dataUsingEncoding:NSUTF8StringEncoding]];
            NSLog(@" \ncn buffer length: %lu",(unsigned long)[buffer length]);
        }
    }else{
        buffer = [NSMutableData dataWithData:[evalPaper dataUsingEncoding:encoding]];
        NSLog(@" \nen buffer length: %lu",(unsigned long)[buffer length]);
    }
    
    BOOL ret = [self.iFlySpeechEvaluator startListening:buffer params:nil];
    if(ret){
        self.isSessionResultAppear = NO;
        self.isSessionEnd = NO;
    }
    
    NSLog(@"%s[OUT]",__func__);
}

/*
 停止录音
 */
RCT_EXPORT_METHOD(stopRecord){
    NSLog(@"%s[IN]",__func__);

    if(self.isSessionEnd){
        NSLog(@"session already ended, make sure call stopRecord after eval session begin.");
    }
    
    if(!self.iFlySpeechEvaluator) {
        NSLog(@"not init");
    }
    else {
        [self.iFlySpeechEvaluator stopListening];
    }
    
    NSLog(@"%s[OUT]",__func__);
}

/*
 取消评测
 */
RCT_EXPORT_METHOD(cancel){
    NSLog(@"%s[IN]",__func__);
    
    if(self.isSessionEnd){
        NSLog(@"session already ended, make sure call cancel after eval session begin.");
    }
    
    if(!self.iFlySpeechEvaluator) {
        NSLog(@"not init");
    }
    else {
        [self.iFlySpeechEvaluator cancel];
    }
    
    NSLog(@"%s[OUT]",__func__);
}


/*!
 *  音量和数据回调
 *
 *  @param volume 音量
 *  @param buffer 音频数据
 */
- (void)onVolumeChanged:(int)volume buffer:(NSData *)buffer {
    //    NSLog(@"volume:%d",volume);
    [self callback:@"volumn" msg:@"录音音量" data:[NSString stringWithFormat:@"%d",volume]];
}

/*!
 *  开始录音回调
 *  当调用了`startListening`函数之后，如果没有发生错误则会回调此函数。如果发生错误则回调onError:函数
 */
- (void)onBeginOfSpeech {
    NSLog(@"speech BEGIN!");
    
    _isBeginOfSpeech =YES;
}

/*!
 *  停止录音回调
 *    当调用了`stopListening`函数或者引擎内部自动检测到断点，如果没有发生错误则回调此函数。
 *  如果发生错误则回调onError:函数
 */
- (void)onEndOfSpeech {
    NSLog(@"speech END!");
}

/*!
 *  正在取消
 */
- (void)onCancel {
    
}

/*!
 *  评测结果回调
 *    在进行语音评测过程中的任何时刻都有可能回调此函数，你可以根据errorCode进行相应的处理.
 *  当errorCode没有错误时，表示此次会话正常结束，否则，表示此次会话有错误发生。特别的当调用
 *  `cancel`函数时，引擎不会自动结束，需要等到回调此函数，才表示此次会话结束。在没有回调此函
 *  数之前如果重新调用了`startListenging`函数则会报错误。
 *
 *  @param errorCode 错误描述类
 */
- (void)onError:(IFlySpeechError *)errorCode {
    if(errorCode && errorCode.errorCode != 0 ) {
        [self callback:@"error" msg:@"" data:[NSString stringWithFormat:@"%d|%@",[errorCode errorCode],[errorCode errorDesc]]];
    }
}

/*!
 *  评测结果回调
 *   在评测过程中可能会多次回调此函数，你最好不要在此回调函数中进行界面的更改等操作，只需要将回调的结果保存起来。
 *
 *  @param results -[out] 评测结果。
 *  @param isLast  -[out] 是否最后一条结果
 */
- (void)onResults:(NSData *)results isLast:(BOOL)isLast{
    if (results) {
        NSString *showText = @"";
        
        const char* chResult=[results bytes];
        
        BOOL isUTF8=[[self.iFlySpeechEvaluator parameterForKey:[IFlySpeechConstant RESULT_ENCODING]]isEqualToString:@"utf-8"];
        NSString* strResults=nil;
        if(isUTF8){
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:NSUTF8StringEncoding];
        }else{
            NSLog(@"result encoding: gb2312");
            NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
            strResults=[[NSString alloc] initWithBytes:chResult length:[results length] encoding:encoding];
        }
        
        if(strResults){
            showText = [showText stringByAppendingString:strResults];
        }
        
        self.isSessionResultAppear = YES;
        self.isSessionEnd = YES;
        if(isLast){
            NSLog(@"speech finished!");
            //转换
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cachePath = [paths objectAtIndex:0];
            NSString *pcmFile = [NSString stringWithFormat:@"%@/%@", cachePath, @"ise.pcm"];
            NSString *wavFile = [NSString stringWithFormat:@"%@/%@", cachePath, @"ise.wav"];
            
            PcmUtil *wavUtil = [[PcmUtil alloc] pcmToWavFile:pcmFile sampleRate:16000 topath:wavFile];
            //[audioPlayer dealloc];
            [self callback:@"file" msg:@"" data:wavFile];
            [self callback:@"result" msg:@"eval finished success" data:showText];
        }
        
    }
    else{
        if(isLast){
            [self callback:@"result" msg:@"eval finished no result" data:@""];
        }
        self.isSessionEnd=  YES;
    }
}

/*
 回调外部 javascript 函数
 */
- (void) callback: (NSString *) type msg:(NSString *)msg data:(NSString *)data
{
    [self sendEventWithName:@"onISECallback"
                       body:@{
                              @"type": type,
                              @"msg": msg,
                              @"data": data,
                            }];
}


/*
 初始化评测实例
 */
- (void) initSpeechEvaluator {
    if (!self.iFlySpeechEvaluator) {
        self.iFlySpeechEvaluator = [IFlySpeechEvaluator sharedInstance];
    }
    
    [self setParams];
    [self.iFlySpeechEvaluator setParameter:@"ise" forKey: [IFlySpeechConstant IFLY_DOMAIN]];
    self.iFlySpeechEvaluator.delegate = self;
}

- (void)setParams {
    [self.iFlySpeechEvaluator setParameter:@"16000" forKey:[IFlySpeechConstant SAMPLE_RATE]];
    [self.iFlySpeechEvaluator setParameter:@"utf-8" forKey:[IFlySpeechConstant TEXT_ENCODING]];
    [self.iFlySpeechEvaluator setParameter:@"xml" forKey:[IFlySpeechConstant ISE_RESULT_TYPE]];
    [self.iFlySpeechEvaluator setParameter:@"zh-cn" forKey:[IFlySpeechConstant LANGUAGE]];
    [self.iFlySpeechEvaluator setParameter:@"5000" forKey:[IFlySpeechConstant VAD_BOS]];
    [self.iFlySpeechEvaluator setParameter:@"3000" forKey:[IFlySpeechConstant VAD_EOS]];
    [self.iFlySpeechEvaluator setParameter:@"300000" forKey:[IFlySpeechConstant SPEECH_TIMEOUT]];
    
    //NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //NSString *docDir = [paths objectAtIndex:0];
    //NSString *wavFile = [NSString stringWithFormat:@"%@/%@", docDir, @"ise.wav"];
    //[self.iFlySpeechEvaluator setParameter:@"wav" forKey:@"audio_format"];
    [self.iFlySpeechEvaluator setParameter:@"ise.pcm" forKey:[IFlySpeechConstant ISE_AUDIO_PATH]];
}

/*
 语音云app id 配置
 */
+(void)crateMyUtility :(NSString *) id{
    //设置sdk的log等级，log保存在下面设置的工作路径中
    [IFlySetting setLogFile:LVL_ALL];
    
    //打开输出在console的log开关
    [IFlySetting showLogcat:YES];
    
    //设置sdk的工作路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    [IFlySetting setLogFilePath:cachePath];
    
    NSString *initString = [[NSString alloc] initWithFormat:@"appid=%@",id];
    [IFlySpeechUtility createUtility:initString];
}

@end
