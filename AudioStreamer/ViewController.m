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
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.queue=[[myaudioqueue alloc]init];
    
  
    
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
    NSString *filePath = [[docDir stringByAppendingPathComponent:[item valueForProperty:MPMediaItemPropertyTitle]] stringByAppendingPathExtension:@"aif"];
    
    exportSession.outputURL = [NSURL fileURLWithPath:filePath];
    
    [exportSession setTimeRange:CMTimeRangeMake(kCMTimeZero, [urlAsset duration])];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // ファイルを移動
     [fileManager removeItemAtPath:filePath error:nil];
    

    // ディレクトリを作成
    [fileManager createDirectoryAtPath:docDir
           withIntermediateDirectories:YES
                            attributes:nil
                                 error:nil];
    
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"export session completed");
           self.queue= [self.queue initWithFilepath:exportSession.outputURL];
            [self.queue play];
           
        } else {
            NSLog(@"export session error");
            
        }
        
    }];
    
    
    
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];

}
-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [mediaPicker dismissViewControllerAnimated:YES completion:nil];
     }
@end
