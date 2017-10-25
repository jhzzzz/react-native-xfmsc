//
//  PcmUtil
//  modified from MSCDemo
//
//  Created by Jack Zhang on 17-10-25.
//
//

#import "PcmUtil.h"

typedef struct Wavehead
{
    /****RIFF WAVE CHUNK*/
    unsigned char a[4];     //四个字节存放'R','I','F','F'
    long int b;             //整个文件的长度-8;每个Chunk的size字段，都是表示除了本Chunk的ID和SIZE字段外的长度;
    unsigned char c[4];     //四个字节存放'W','A','V','E'
    /****RIFF WAVE CHUNK*/
    /****Format CHUNK*/
    unsigned char d[4];     //四个字节存放'f','m','t',''
    long int e;             //16后没有附加消息，18后有附加消息；一般为16，其他格式转来的话为18
    short int f;            //编码方式，一般为0x0001;
    short int g;            //声道数目，1单声道，2双声道;
    int h;                  //采样频率;
    unsigned int i;         //每秒所需字节数;
    short int j;            //每个采样需要多少字节，若声道是双，则两个一起考虑;
    short int k;            //即量化位数
    /****Format CHUNK*/
    /***Data Chunk**/
    unsigned char p[4];     //四个字节存放'd','a','t','a'
    long int q;             //语音数据部分长度，不包括文件头的任何部分
} WaveHead;//定义WAVE文件的文件头结构体


@interface PcmUtil ()

@property (nonatomic,strong) NSMutableData *pcmData;
@property (nonatomic,strong) NSTimer *timer;

@end

@implementation PcmUtil




-(id)pcmToWavFile:(NSString *)path sampleRate:(long)sample topath:(NSString *)topath
{    
    if (self) {
        NSData *audioData = [NSData dataWithContentsOfFile:path];
        [self writeWaveHead:audioData sampleRate:sample topath:topath];
        NSLog(@"nihao");
    }
    return self;
}

/**
 *
 *  写wave音频头,写完回调 onAudioLoaded 函数
 *
 */
- (void)writeWaveHead:(NSData *)audioData sampleRate:(long)sampleRate topath:(NSString *)topath{
    Byte waveHead[44];
    waveHead[0] = 'R';
    waveHead[1] = 'I';
    waveHead[2] = 'F';
    waveHead[3] = 'F';
    
    long totalDatalength = [audioData length] + 44;
    waveHead[4] = (Byte)(totalDatalength & 0xff);
    waveHead[5] = (Byte)((totalDatalength >> 8) & 0xff);
    waveHead[6] = (Byte)((totalDatalength >> 16) & 0xff);
    waveHead[7] = (Byte)((totalDatalength >> 24) & 0xff);
    
    waveHead[8] = 'W';
    waveHead[9] = 'A';
    waveHead[10] = 'V';
    waveHead[11] = 'E';
    
    waveHead[12] = 'f';
    waveHead[13] = 'm';
    waveHead[14] = 't';
    waveHead[15] = ' ';
    
    waveHead[16] = 16;  //size of 'fmt '
    waveHead[17] = 0;
    waveHead[18] = 0;
    waveHead[19] = 0;
    
    waveHead[20] = 1;   //format
    waveHead[21] = 0;
    
    waveHead[22] = 1;   //chanel
    waveHead[23] = 0;
    
    waveHead[24] = (Byte)(sampleRate & 0xff);
    waveHead[25] = (Byte)((sampleRate >> 8) & 0xff);
    waveHead[26] = (Byte)((sampleRate >> 16) & 0xff);
    waveHead[27] = (Byte)((sampleRate >> 24) & 0xff);
    
    long byteRate = sampleRate * 2 * (16 >> 3);;
    waveHead[28] = (Byte)(byteRate & 0xff);
    waveHead[29] = (Byte)((byteRate >> 8) & 0xff);
    waveHead[30] = (Byte)((byteRate >> 16) & 0xff);
    waveHead[31] = (Byte)((byteRate >> 24) & 0xff);
    
    waveHead[32] = 2*(16 >> 3);
    waveHead[33] = 0;
    
    waveHead[34] = 16;
    waveHead[35] = 0;
    
    waveHead[36] = 'd';
    waveHead[37] = 'a';
    waveHead[38] = 't';
    waveHead[39] = 'a';
    
    long totalAudiolength = [audioData length];
    
    waveHead[40] = (Byte)(totalAudiolength & 0xff);
    waveHead[41] = (Byte)((totalAudiolength >> 8) & 0xff);
    waveHead[42] = (Byte)((totalAudiolength >> 16) & 0xff);
    waveHead[43] = (Byte)((totalAudiolength >> 24) & 0xff);
    
    self.pcmData = [[NSMutableData alloc]initWithBytes:&waveHead length:sizeof(waveHead)];
    [self.pcmData appendData:audioData];

    [self.pcmData writeToFile:topath atomically:YES];
}

@end
