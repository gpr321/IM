//
//  GPIMTool.h
//  GPTCPScoketTool
//
//  Created by mac on 15/4/5.
//  Copyright (c) 2015年 gpr. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^IMFailBlock)(NSError *error);
typedef void(^IMReceiveMessageBlock)(NSString *message);

extern NSString *const kIMUserInfoMessageKey;

typedef NS_ENUM(NSInteger, IMErrorCode) {
    IMErrorCodeSocketCreateFail = 100,      // 创建 socket 失败
    IMErrorCodeConnectFail,                 // 连接失败
    IMErrorCodeConnectTimeOut,              // 连接超时
};

// LOG
#ifdef DEBUG
#define GPLog(...) NSLog(__VA_ARGS__)
#else
#define GPLog(...)
#endif

/*
 * 注意如果在子线程中使用此工具请开启自动释放池
 */
@interface GPIMTool : NSObject

/** 默认为 15 s  */
@property (nonatomic,assign) NSTimeInterval timeOunt;
/** 用来限制接收的字符的最大长度，默认为256 */
@property (nonatomic,assign) int messageBuffer;

+ (instancetype)shareInstance;

/**
 *  连接到服务器,如果
 *
 *  @param address   服务器地址
 *  @param port      端口
 *  @param failBlock 失败的回调 error.code = IMErrorCode
 */
- (void)connectToServerWithAddress:(NSString *)address port:(NSInteger)port fail:(IMFailBlock)failBlock;

/**
 *  发送一条聊天内容到服务器
 *
 *  @param message   聊天的具体内容,如果为空或者长度为0则默认不发送
 *  @param failBlock 发送失败的回调
 */
- (void)sendMessage:(NSString *)message fail:(void(^)())failBlock;

/**
 *  默认会开启一个死循环来监听服务器发送过来的信息
 *
 *  @param msgBlock 消息回调
 */
- (void)waitForMessage:(IMReceiveMessageBlock)msgBlock;

/**
 *  断开连接
 */
- (void)disconnect;

/**
 *  重新连接
 */
- (void)reconnect;

@end
