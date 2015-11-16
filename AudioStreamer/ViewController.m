//
//  ViewController.m
//  AudioStreamer
//
//  Created by 椛島優 on 2015/10/22.
//  Copyright © 2015年 椛島優. All rights reserved.
///

#import "ViewController.h"

@interface ViewController ()
@property MPMusicPlayerController * controler;
@property myaudioqueue * queue;
@property MultipeerHost * myMulti;
@property StreamingPlayer * StPlayer;
@property AudioConverter *converter;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.queue=[[myaudioqueue alloc]init];
    self.myMulti=[[MultipeerHost alloc]init];
    self.myMulti.delegate=self;
    self.StPlayer=[[StreamingPlayer alloc]init];
    [self.StPlayer start];
    [self.myMulti startClient];
    self.converter=[[AudioConverter alloc]init];
  
    
        // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)SelectBtnTap:(id)sender {
    
    MPMediaPickerController *picker = [[MPMediaPickerController alloc]init];
    picker.delegate = self;
    picker.allowsPickingMultipleItems = NO;        // 複数選択可
    [self presentViewController:picker animated:YES completion:nil];
}

//delegate
-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    MPMediaItem *item=[mediaItemCollection.items objectAtIndex:0];
    NSURL *url=[item valueForProperty:MPMediaItemPropertyAssetURL];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc]
                                           initWithAsset:urlAsset
                                           presetName:AVAssetExportPresetAppleM4A];
    
    exportSession.outputFileType = [[exportSession supportedFileTypes] objectAtIndex:0];
    
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [[docDir stringByAppendingPathComponent:[item valueForProperty:MPMediaItemPropertyTitle]] stringByAppendingPathExtension:@"m4a"];
    NSString *savePath=[filePath stringByDeletingPathExtension];
    savePath=[savePath stringByAppendingPathExtension:@"caf"];
    exportSession.outputURL = [NSURL fileURLWithPath:filePath];
    
    [exportSession setTimeRange:CMTimeRangeMake(kCMTimeZero, [urlAsset duration])];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // ファイルを移動
     [fileManager removeItemAtPath:filePath error:nil];
    [fileManager removeItemAtPath:savePath error:nil];

    // ディレクトリを作成
    [fileManager createDirectoryAtPath:docDir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"export session completed");
          
            NSLog(@"%@",exportSession.outputURL);
            NSURL*SaveURL=[NSURL fileURLWithPath:savePath];
            UInt32 fileType;
            
            //変換するフォーマット
            AudioStreamBasicDescription outputFormat;
            memset(&outputFormat, 0, sizeof(AudioStreamBasicDescription));
            
            if(1)
            {
                outputFormat.mSampleRate		= 44100.0;
                outputFormat.mFormatID			= kAudioFormatLinearPCM;
                outputFormat.mFormatFlags		= kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
                outputFormat.mFramesPerPacket	= 1;
                outputFormat.mChannelsPerFrame	= 2;
                outputFormat.mBitsPerChannel	= 16;
                outputFormat.mBytesPerPacket	= 4;
                outputFormat.mBytesPerFrame		= 4;
                outputFormat.mReserved			= 0;
                fileType = kAudioFileCAFType;
            }
            
            [self.converter convertFrom:exportSession.outputURL toURL:SaveURL format:outputFormat fileType:fileType];
            
            //変換するフォーマット
            
            
            AudioSessionInitialize(NULL, NULL, NULL, NULL);
            AudioSessionSetActive(YES);
            UInt32 audioCategory;
            audioCategory = kAudioSessionCategory_AudioProcessing;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory,
                                    sizeof(audioCategory),
                                    &audioCategory);
            
            NSString *ssavePath=[filePath stringByDeletingPathExtension];
            ssavePath=[ssavePath stringByAppendingPathExtension:@"aac"];
            NSURL*SsaveURL=[NSURL fileURLWithPath:ssavePath];

            //変換するフォーマット(AAC)
          
            memset(&outputFormat, 0, sizeof(AudioStreamBasicDescription));
            outputFormat.mSampleRate       = 44100.0;
            outputFormat.mFormatID         = kAudioFormatMPEG4AAC;//AAC
            outputFormat.mChannelsPerFrame = 1;
            
            UInt32 size = sizeof(AudioStreamBasicDescription);
            AudioFormatGetProperty(kAudioFormatProperty_FormatInfo,
                                   0, NULL,
                                   &size,
                                   &outputFormat);
            
            ExtAudioConverter *extConverter = [[ExtAudioConverter alloc]init];
            [extConverter convertFrom:SaveURL toURL:SsaveURL format:outputFormat];
            
            audioCategory = kAudioSessionCategory_MediaPlayback;
            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, 
                                    sizeof(audioCategory), 
                                    &audioCategory);
             self.queue= [self.queue initWithFilepath:exportSession.outputURL];
            [self.queue play];
            NSData*data=[[NSData alloc]initWithContentsOfURL:SsaveURL];
            [self.myMulti sendData:data];
           
        } else {
            NSLog(@"export session error");
            
        }
        
    }];
    
    
    
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];

}
-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
     }
-(void)recvDataPacket:(NSData *)data{
    [self.StPlayer recvAudio:data];
}
- (IBAction)inviteBtnTap:(id)sender {
     [self.myMulti startHost];
    [self.myMulti stopClient];
}

@end
