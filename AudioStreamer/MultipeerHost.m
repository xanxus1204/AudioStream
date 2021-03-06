//
//  MultipeerHost.m
//  Multipeer0220
//
//  Created by 椛島優 on 2015/02/20.
//  Copyright (c) 2015年 椛島優. All rights reserved.
//
//８人までに限定してつくる。

#import "MultipeerHost.h"
@interface MultipeerHost()
@property MCPeerID *mPeerID;
@property MCSession *mSession;
@property MCNearbyServiceAdvertiser *nearbyAd;
@property NSMutableArray *connectedpeer;
@property NSArray *invitationArr;
@property MCNearbyServiceBrowser *browser;
@property int nowinvitees;
@property BOOL solo;
@property int count;
@property NSMutableData *recvData;
@property NSInputStream *iStream;
@property NSOutputStream *oStream;
@property NSMutableData *mdata;
@property int datacount;
-(void)postNotification;
-(void)postNotificationc;
@end

@implementation MultipeerHost


-(void)startClient{
    if (self.connectedpeer.count==0) {
    self.connectedpeer=[[NSMutableArray alloc]init];
    self.mPeerID = [[MCPeerID alloc] initWithDisplayName:[[UIDevice currentDevice]name]];
    //セッションを初期化
    self.mSession= [[MCSession alloc] initWithPeer:self.mPeerID];
    //デリゲートを設定
    self.mSession.delegate = self;
    
    self.nearbyAd=[[MCNearbyServiceAdvertiser alloc]initWithPeer:self.mPeerID discoveryInfo:nil serviceType:@"kurumecs"];
    self.nearbyAd.delegate=self;
    [self.nearbyAd startAdvertisingPeer];
        _recvData = [[NSMutableData alloc]init];
        
    }
   
    
}
-(void)startHost{
    self.nowinvitees=0;
    [self.nearbyAd stopAdvertisingPeer];
    if (self.browser==nil) {
    self.browser = [[MCNearbyServiceBrowser alloc]
                    initWithPeer:self.mPeerID
                    serviceType:@"kurumecs"];
    
    
    self.browser.delegate = self;
    }
    
    [self.browser startBrowsingForPeers];
    
   
    

}
-(id)init{
    if (self=[super init]){
        self.solo=YES;
       
    }
    return  self;
}
//Multipeer Connectivity delegate
// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state{
    
    if (state==MCSessionStateConnected) {
        NSLog(@"接続完了");
        self.solo=NO;
        [self  stopClient];
        if (!([self.connectedpeer containsObject:peerID])) {
            
            [self.connectedpeer addObject:peerID];
            self.oStream = [self.mSession startStreamWithName:@"test" toPeer:peerID error:nil];
            self.oStream.delegate=self;
            [self.oStream open];
            [self.oStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            [self postNotificationc];

            
            
            self.nowinvitees--;
            
        }
    }
    if (state==MCSessionStateNotConnected) {
        NSLog(@"抜けた");
        [self.connectedpeer removeObject:peerID];
        if (self.connectedpeer.count==0) {
            self.solo=YES;
        }
        [self postNotificationc];
        
        
    }
    
}

// Received data from remote peer
-(void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID{
   
   
   
}




-(void)sendStr:(NSString *)str{
    
    
    NSData*keyData=[str dataUsingEncoding:NSUTF8StringEncoding];
    [self.mSession sendData:keyData
                   toPeers:self.connectedpeer
                  withMode:MCSessionSendDataReliable
                     error:nil];
      
    

    
}
-(void)sendList:(NSArray *)arr{
    NSData*keyData=[NSKeyedArchiver archivedDataWithRootObject:arr];
    [self.mSession sendData:keyData toPeers:self.connectedpeer withMode:MCSessionSendDataReliable error:nil];
}
-(void)sendData:(NSData *)data{
    
    NSInteger bytesWritten = 0;
    NSInteger d=0;
    int ini;
    u_int8_t buf[BUF];
    _mdata = [[NSMutableData alloc]init];
    
    for ( ini=0; ini<=data.length; ini=ini+BUF) {
               while (1) {
                if ([self.oStream hasSpaceAvailable])
                    break;
                
            }
        
            d=BUF;
            if ((ini>=data.length-BUF)||(data.length<BUF)){
                d=data.length-ini;
                u_int8_t buf[d];
                NSLog(@"%ld",(unsigned long)data.length);
                [data getBytes:buf range:NSMakeRange(ini,d)];
                _mdata=[_mdata initWithBytes:buf length:sizeof(buf)];
             //   NSData*keyData=[@"EndOfFile" dataUsingEncoding:NSUTF8StringEncoding];
                
                NSInteger writebytesremain=0;
                do{
                    
                    _mdata=[_mdata initWithBytes:&buf[writebytesremain] length:sizeof(buf)-writebytesremain];
                    
                    bytesWritten=[self.oStream write:_mdata.bytes maxLength:_mdata.length];
                    if(bytesWritten==-1){
                        NSLog(@"途中抜け");
                        
                        break;
                    }
                    writebytesremain=writebytesremain+bytesWritten;
                    
                    
                }while(writebytesremain!=sizeof(buf));
                
                [NSThread sleepForTimeInterval:0.30];
                //[self.oStream write:keyData.bytes maxLength:keyData.length];
                NSLog(@"送信完了");
                
                
            }else{
                
                [data getBytes:buf range:NSMakeRange(ini,d)];
                NSInteger writebytesremain=0;
                do{
                    
                    _mdata=[_mdata initWithBytes:&buf[writebytesremain] length:sizeof(buf)-writebytesremain];
                    
                    bytesWritten=[self.oStream write:_mdata.bytes maxLength:_mdata.length];
                    if(bytesWritten==-1){
                        NSLog(@"途中抜け");
                        
                        break;
                    }
                    
                    writebytesremain=writebytesremain+bytesWritten;
                    
                   
                    
                 
                }while(writebytesremain!=sizeof(buf));
                
                
            }
    }
    
        

    


}
//MCNearByBrowser delegate
// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info{
    
    if (self.nowinvitees==7){
        
    }else{
        
    
        
    [browser invitePeer:peerID
              toSession:self.mSession //要変更か　インスタンスを新しく用意する手法に変更。
            withContext:nil
                timeout:0];//30s
    self.nowinvitees++;
    
    }
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID{
    
}

// Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler{
    
    _invitationArr=[NSArray arrayWithObject:[invitationHandler copy]];
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"同時再生"
                              message:@"参加しますか？"
                              delegate:self
                              cancelButtonTitle:@"拒否"
                              otherButtonTitles:@"参加", nil];
                              // present alert view
                              [alertView show];
    
    
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // retrieve the invitationHandler
    // get user decision
    BOOL accept = (buttonIndex != alertView.cancelButtonIndex) ? YES : NO;
    if(accept) {
        void (^invitationHandler)(BOOL, MCSession *) = [_invitationArr objectAtIndex:0];
        invitationHandler(accept, self.mSession);
        NSLog(@"いいよ");
    }
    else
    {
        NSLog(@"Session disallowed");
        
    }

    // respond
    
}


-(void)postNotification
{
    //
    NSNotificationCenter *nc =
    [NSNotificationCenter defaultCenter];
    
    // 通知する
    [nc postNotificationName:@"recv"
                      object:self
                    userInfo:nil];
}



-(void)postNotificationc
{
    NSNotificationCenter *nc =
    [NSNotificationCenter defaultCenter];
    
    // 通知する
    [nc postNotificationName:@"conn"
                      object:self
                    userInfo:nil];

}

-(void)stopClient{
    [self.nearbyAd stopAdvertisingPeer];
    self.nearbyAd.delegate=nil;
    
}


-(void)stopHost{
     [self.browser stopBrowsingForPeers];
    self.browser.delegate=nil;
}






// require delegate method

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID{
    NSLog(@"input %@",streamName);
    self.iStream=stream;
    self.iStream.delegate=self;
    [self.iStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [self.iStream open];
    NSLog(@"%lu", (unsigned long)self.iStream.streamStatus);
    
}

- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress{
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error{
    
}
-(BOOL)fileCreate:(NSString *)path andData:(NSData *)data{
    NSFileManager *fm=[NSFileManager defaultManager];
    BOOL flag=[fm createFileAtPath:path contents:data attributes:nil];
    
    NSData*lastdata=[fm contentsAtPath:path];
    NSLog(@"ファイルおわり%ld",(unsigned long)lastdata.length);
    return flag;
}
//NSStream delegate
-(void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode{//データを受け取るなどの動作
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"空いた");
            break;
        case NSStreamEventHasBytesAvailable:{
            NSUInteger bytesRead;
            uint8_t buffer[32768];
            bytesRead = [self.iStream read:buffer maxLength:sizeof(buffer)];
            if (bytesRead == -1) {
                
            }else if(bytesRead == 0){
                
                
            }else{
               
                NSInteger bytesWritten;
                NSInteger bytesWrittenSoFar;
                bytesWrittenSoFar = 0;
                _recvData=[_recvData init];
                do{
                    
                    [_recvData appendBytes:&buffer[bytesWrittenSoFar]
                                  length:bytesRead-bytesWrittenSoFar];
                    bytesWritten = [_recvData length];
                if (bytesWritten == -1) {
                        break;
                    }else{
                        bytesWrittenSoFar += bytesRead;
                    }
                }while (bytesWrittenSoFar != bytesRead);
                [self recvDataPacket];

                
            }
            break;
        }
    
        case NSStreamEventHasSpaceAvailable:
            
            break;
        case NSStreamEventErrorOccurred:
            
            break;
        case NSStreamEventEndEncountered:{
            
            
            break;
        }
        default:
            break;
    }
}
-(void)recvDataPacket{
    if([self.delegate respondsToSelector:@selector(recvDataPacket:)]){
       // NSLog(@"%ld",(unsigned long)_recvData.length);
        self.datacount=self.datacount+(int)_recvData.length;
        NSLog(@"%d",self.datacount);
        [self.delegate recvDataPacket:_recvData];
    }
}
@end
