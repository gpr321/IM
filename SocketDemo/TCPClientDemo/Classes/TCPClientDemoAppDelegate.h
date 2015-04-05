//
//  TCPClientDemoAppDelegate.h
//  TCPClientDemo
//
//  Created by 赵 栓 on 09-10-10.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "ChatViewController.h"
#import "ConnectViewController.h"

@interface TCPClientDemoAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
	ChatViewController *chatController;
	ConnectViewController *connController;
	
	CFSocketRef _socket;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) ChatViewController *chatController;
@property (nonatomic, retain) ConnectViewController *connController;

- (void) doConnect;
- (void) sendMessage;
- (void) setTextInMainThread:(NSString *)text;

@end

