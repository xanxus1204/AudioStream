//
//  myaudioqueue.h
//  audioqueue
//
//  Created by 椛島優 on 2015/10/14.
//  Copyright © 2015年 椛島優. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

#define kNumberBuffers 3
#define kBufferSeconds 0.5 // 0.5秒ずつバッファに入れる
@interface myaudioqueue : NSObject{
    NSURL                        *filepath;
    AudioStreamBasicDescription  audioDataFormat;
    AudioQueueRef                audioQueue;
    AudioQueueBufferRef          audioBuffers[kNumberBuffers];
    AudioFileID                  inAudioFile;
    AudioStreamPacketDescription *audioPacketDesc;
    UInt32                       indexPacket;
    UInt32                       numPacketsToRead;
    UInt32                       playStatus;
}
- (id)initWithFilepath:(NSURL *)path;
- (void)play;
@property NSData *data;
@end
