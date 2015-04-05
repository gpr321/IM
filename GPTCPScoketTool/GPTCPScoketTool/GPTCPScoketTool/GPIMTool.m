//
//  GPIMTool.m
//  GPTCPScoketTool
//
//  Created by mac on 15/4/5.
//  Copyright (c) 2015年 gpr. All rights reserved.
//

#import "GPIMTool.h"
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

NSString *const kIMUserInfoMessageKey = @"kIMUserInfoMessageKey";

@interface GPIMTool ()
{
    CFSocketRef                 _socket;                // 套接字对象
    BOOL                        _isReceiveMsg;          // 用来标识是否接收消息
}
@property (nonatomic,copy) IMFailBlock failBlock;
@property (nonatomic,copy) NSString *address;
@property (nonatomic,assign) NSInteger port;
@end

@implementation GPIMTool

+ (instancetype)shareInstance{
    static GPIMTool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init{
    if ( self = [super init] ) {
        [self setUp];
    }
    return self;
}

- (void)setUp{
    self.timeOunt = 2;
    self.messageBuffer = 256;
}

- (void)dealloc{
    if ( _socket ) {
        CFRelease(_socket);
    }
}

- (void)waitForMessage:(IMReceiveMessageBlock)msgBlock{
    char buf[self.messageBuffer];
    while (recv(CFSocketGetNative(_socket), buf, sizeof(buf), 0)) {
        @autoreleasepool {
            NSString *msg = [NSString stringWithUTF8String:buf];
            msgBlock(msg);
        }
    }
}

- (void)sendMessage:(NSString *)message fail:(void(^)())failBlock{
    if ( message.length == 0 ) return;
    message = [message copy];
    const char *data = message.UTF8String;
    if ( send(CFSocketGetNative(_socket), data, strlen(data) + 1, 0) < 0 && failBlock ){
        failBlock();
    }
}

- (void)connectToServerWithAddress:(NSString *)address port:(NSInteger)port fail:(IMFailBlock)failBlock{
    [self disconnect];
    self.failBlock = failBlock;
    self.address = [address copy];
    CFSocketContext CTX = {0, (__bridge void *)(self), NULL, NULL, NULL};
    _socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack, TCPServerConnectCallBack, &CTX);
    if ( NULL == _socket ) {
        [self failBlockWithErrorMessage:@"创建套接字失败" errorCode:IMErrorCodeSocketCreateFail];
        return;
    }
    // 设置开启心跳帧选项
    int keepAlive = 1;
    setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_KEEPALIVE, &keepAlive, sizeof(keepAlive));
    // SO_REUSEADDR
    
    struct sockaddr_in addr4;
    memset(&addr4, 0, sizeof(addr4));
    addr4.sin_len = sizeof(addr4);
    addr4.sin_family = AF_INET;
    addr4.sin_port = htons(port);
    addr4.sin_addr.s_addr = inet_addr(self.address.UTF8String);
    CFDataRef addr = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
    switch ( CFSocketConnectToAddress(_socket, addr, self.timeOunt) ) {
        case kCFSocketError:
            [self failBlockWithErrorMessage:@"连接失败" errorCode:IMErrorCodeConnectFail];
            return;
            break;
        case kCFSocketTimeout:
            [self failBlockWithErrorMessage:@"连接超时" errorCode:IMErrorCodeConnectTimeOut];
            return;
            break;
        default:
            GPLog(@"连接成功");
            break;
    }
    // 把当前信息添加到运行循环中以便监听信息
    CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
    CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
    CFRelease(source);
    CFRelease(addr);
}

- (void)disconnect{
    if ( _socket ) {
        CFSocketInvalidate(_socket);
        // close( CFSocketGetNative(_socket) );
        CFRelease(_socket);
        _socket = NULL;
    }
}

- (void)reconnect{
    [self connectToServerWithAddress:self.address port:self.port fail:self.failBlock];
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

static void TCPServerConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    if (data != NULL) {
        [[GPIMTool shareInstance] failBlockWithErrorMessage:@"连接失败" errorCode:IMErrorCodeConnectFail];
        return;
    }
}

@end
