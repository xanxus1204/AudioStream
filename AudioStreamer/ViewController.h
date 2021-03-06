//
//  ViewController.h
//  AudioStreamer
//
//  Created by 椛島優 on 2015/10/22.
//  Copyright © 2015年 椛島優. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "myaudioqueue.h"
#import "MultipeerHost.h"
#import "StreamingPlayer.h"
#import "AudioConverter.h"
#import "ExtAudioConverter.h"
@interface ViewController : UIViewController<MPMediaPickerControllerDelegate,MultipeerDataDelegate>


@end

