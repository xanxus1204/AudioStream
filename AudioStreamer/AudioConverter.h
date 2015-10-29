//
//  AudioConverter.h
//  AudioStreamer
//
//  Created by 椛島優 on 2015/10/29.
//  Copyright © 2015年 椛島優. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
@interface AudioConverter : NSObject
-(void)convertFrom:(NSURL*)fromURL toURL:(NSURL*)toURL format:(AudioStreamBasicDescription)outputFormat;

@end
