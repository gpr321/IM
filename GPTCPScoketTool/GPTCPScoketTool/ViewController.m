//
//  ViewController.m
//  GPTCPScoketTool
//
//  Created by mac on 15/4/5.
//  Copyright (c) 2015年 gpr. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import "CCIMTool.h"

@interface ViewController ()<GCDAsyncSocketDelegate>

@property (nonatomic,assign) BOOL connect;

@property (nonatomic,strong) GCDAsyncSocket *socket;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[CCIMTool shareInstance] connectToServerWithAddress:@"127.0.0.1" port:12345 fail:^(NSError *error) {
        NSLog(@"连接失败");
    }];
    [[CCIMTool shareInstance] sendMessage:@"hello" fail:^{
        NSLog(@"发送消息失败");
    }];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if ( !self.connect ) {
        [[CCIMTool shareInstance] reconnect];
        self.connect = !self.connect;
    } else {
        [[CCIMTool shareInstance] disconnect];
        self.connect = !self.connect;
    }
}

@end
