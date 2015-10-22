//
//  myaudioqueue.m
//  audioqueue
//
//  Created by 椛島優 on 2015/10/14.
//  Copyright © 2015年 椛島優. All rights reserved.
//

#import "myaudioqueue.h"

@implementation myaudioqueue
static void AQOutputCallback(void *userData,
                             AudioQueueRef audioQueueRef,
                             AudioQueueBufferRef audioQueueBufferRef) {
    
    myaudioqueue *player = (__bridge myaudioqueue*)userData;
    [player audioQueueOutputWithQueue:audioQueueRef queueBuffer:audioQueueBufferRef];
}

- (id)initWithFilepath:(NSURL *)path {
    indexPacket = 0;
    
    filepath = path;
    
    // オーディオキューを作成する
    [self createAudioQueue];
    
    // 再生の事前準備をする
    [self prepareToPlay];
    
    return self;
}

- (void)createAudioQueue {
    UInt32 propertySize;
    
    // 再生するオーディオファイルを読み込み権限で開く
    AudioFileOpenURL((CFURLRef)CFBridgingRetain(filepath),
                     kAudioFileReadPermission,
                     0,
                     &inAudioFile);
    
    // オーディオデータフォーマットの情報をaudioDataFormatへセット
    propertySize = sizeof(audioDataFormat);
    AudioFileGetProperty(inAudioFile,
                         kAudioFilePropertyDataFormat,
                         &propertySize,
                         &audioDataFormat);
    
    // 再生用のオーディオキューオブジェクトを作成する
    AudioQueueNewOutput(
                        &audioDataFormat, // AudioStreamBasicDescription
                        AQOutputCallback, // AudioQueueOutputCallback
                        (void *)CFBridgingRetain(self), // コールバックの第一引数に渡される
                        nil,
                        nil,
                        0,
                        &audioQueue);
}

- (void)prepareToPlay {
    UInt32 propertySize;
    
    // パケットの最大バイト数を取得
    UInt32 maxPacketSize;
    propertySize = sizeof(maxPacketSize);
    AudioFileGetProperty(
                         inAudioFile,
                         kAudioFilePropertyPacketSizeUpperBound,
                         &propertySize,
                         &maxPacketSize);
    
    // 毎秒のパケット数
    Float64 numPacketsPerSecond;
    numPacketsPerSecond = audioDataFormat.mSampleRate / audioDataFormat.mFramesPerPacket;
    
    UInt32 bufferSize;
    bufferSize = numPacketsPerSecond * maxPacketSize * kNumberBuffers;
    
    numPacketsToRead = numPacketsPerSecond * kBufferSeconds;
    
    audioPacketDesc = malloc(numPacketsToRead * sizeof(AudioStreamPacketDescription));
    
    // バッファを作成
    for (int i = 0; i < kNumberBuffers; i++) {
        AudioQueueAllocateBuffer(audioQueue, bufferSize, &audioBuffers[i]);
    }
    
}

- (void) audioQueueOutputWithQueue:(AudioQueueRef)audioQueueRef
                       queueBuffer:(AudioQueueBufferRef)audioQueueBufferRef {
    
    UInt32 numBytes;
    UInt32 numPackets = numPacketsToRead;
    
    // パケットを読み込む
    AudioFileReadPackets(inAudioFile,
                         NO,
                         &numBytes,
                         audioPacketDesc,
                         indexPacket,
                         &numPackets,
                         audioQueueBufferRef->mAudioData);
    
    if (numPackets > 0) {
        audioQueueBufferRef->mAudioDataByteSize = numBytes;
        AudioQueueEnqueueBuffer(audioQueueRef,
                                audioQueueBufferRef,
                                numPackets,
                                audioPacketDesc);
               [self postNotificationc];
        // 次のパケットを読み込むようにする
        indexPacket += numPackets;
    }
}


-(void)play {
    for(int i=0; i<kNumberBuffers; i++){
        [self audioQueueOutputWithQueue:audioQueue queueBuffer:audioBuffers[i]];
    }
    
    AudioQueueStart(audioQueue, nil);
}
-(void)postNotificationc
{
    NSNotificationCenter *nc =
    [NSNotificationCenter defaultCenter];
    
    // 通知する
    [nc postNotificationName:@"buff"
                      object:self
                    userInfo:nil];
    
}

@end
