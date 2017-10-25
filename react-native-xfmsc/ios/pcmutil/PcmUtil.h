//
//  pcmPlayer.h
//  MSCDemo
//
//  Created by wangdan on 14-11-4.
//
//

#import <Foundation/Foundation.h>
#import<AVFoundation/AVFoundation.h>

@interface PcmUtil : NSObject

/**
 * 初始化，并传入音频的本地路径
 *
 * path   音频pcm文件完整路径
 * sample 音频pcm文件采样率，支持8000和16000两种
 ****/
-(id)pcmToWavFile:(NSString *)path sampleRate:(long)sample topath:(NSString *)topath;

@end
