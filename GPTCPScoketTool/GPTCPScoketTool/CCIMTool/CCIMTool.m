//
//  CCIMTool.m
//  GPTCPScoketTool
//
//  Created by mac on 15/4/5.
//  Copyright (c) 2015年 gpr. All rights reserved.
//

#import "CCIMTool.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface CCIMTool ()
{
    int _socket;
}
@property (nonatomic,assign) int socket;

@property (nonatomic,copy) NSString *address;

@property (nonatomic,assign) NSInteger port;

@property (nonatomic,copy) IMFailBlock failBlock;

@property (nonatomic,assign) BOOL waitForMessage;

@end

@implementation CCIMTool

+ (instancetype)shareInstance{
    static CCIMTool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init{
    if ( self = [super init] ) {
        self.messageBufferSize = 256;
    }
    return self;
}

- (void)connectToServerWithAddress:(NSString *)address port:(NSInteger)port fail:(IMFailBlock)failBlock{
    [self disconnect];
#ifdef DEBUG
    NSAssert(address.length, @"地址不能为空");
#endif
    self.address = address;
    self.port = port;
    self.failBlock = failBlock;
    _socket = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    
    struct sockaddr_in serverAddress;
    serverAddress.sin_family = AF_INET;
    serverAddress.sin_port = htons(port);
    serverAddress.sin_addr.s_addr = inet_addr(address.UTF8String);
    if ( connect(_socket, (struct sockaddr *)&serverAddress, sizeof(serverAddress)) ) {
        [self failBlockWithErrorMessage:@"连接失败" errorCode:IMErrorCodeConnectFail];
    }
    self.failBlock = nil;
}

- (void)disconnect{
    if ( _socket && close(_socket) ) {
        GPLog(@"关闭失败");
    }
    self.waitForMessage = NO;
    _socket = 0;
}

- (void)reconnect{
    [self disconnect];
    [self connectToServerWithAddress:self.address port:self.port fail:self.failBlock];
}

- (void)waitForMessage:(IMReceiveMessageBlock)msgBlock{
    char buf[self.messageBufferSize];
    self.waitForMessage = YES;
    size_t length = 0;
    while ( (length = recv(_socket, buf, sizeof(self.messageBufferSize), 0)) && self.waitForMessage ) {
        @autoreleasepool {
            NSData *data = [NSData dataWithBytes:buf length:length];
            NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            msgBlock(message);
            GPLog(@"message : %@",message);
        }
    }
}

- (void)sendMessage:(NSString *)message fail:(void (^)())failBlock{
    self.failBlock = failBlock;
    const char *cMessage = message.UTF8String;
    send(_socket, cMessage, strlen(cMessage) + 1, 0);
}

- (void)failBlockWithErrorMessage:(NSString *)errorMessage errorCode:(IMErrorCode)errorCode{
    if ( self.failBlock ) {
        NSDictionary *userInfo = nil;
        if ( errorMessage ) {
            userInfo = @{kIMUserInfoMessageKey: errorMessage};
        }
        NSError *error = [NSError errorWithDomain:@"domain" code:errorCode userInfo:userInfo];
        self.failBlock(error);
    }
}

@end
