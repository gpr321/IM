//
//	TCPClientDemoAppDelegate.m
//	TCPClientDemo
//
//	Created by 赵 栓 on 09-10-10.
//	Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "TCPClientDemoAppDelegate.h"

@implementation TCPClientDemoAppDelegate

@synthesize window;
@synthesize chatController;
@synthesize connController;


- (void)applicationDidFinishLaunching:(UIApplication *)application {
	chatController = [[ChatViewController alloc] initWithNibName:nil bundle:nil];
	chatController.view.frame = [UIScreen mainScreen].applicationFrame;
	connController = [[ConnectViewController alloc] initWithNibName:nil bundle:nil];
	[window addSubview:chatController.view];
	[window makeKeyAndVisible];
	[chatController presentModalViewController:connController animated:NO];
	
	chatController.button.target = self;
	chatController.button.action = @selector(sendMessage);
	[connController.button addTarget:self action:@selector(doConnect) forControlEvents:UIControlEventTouchDown];
}


- (void)dealloc {
	[chatController release];
	[connController release];
	[window release];
	[super dealloc];
}

- (void)setTextInMainThread:(NSString *)text {
	NSRange endRange;
	endRange.location = [chatController.textView.text length];
	endRange.length = [text length];
	chatController.textView.text = [chatController.textView.text stringByAppendingString:[@"server: " stringByAppendingString:text]];;
	[chatController.textView scrollRangeToVisible:endRange];
}

- (void)readStream {
	char buffer[255];
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	while (recv(CFSocketGetNative(_socket), buffer, sizeof(buffer), 0)) {
		NSString *s = [NSString stringWithUTF8String:buffer];
		[self performSelectorOnMainThread:@selector(setTextInMainThread:) withObject:s waitUntilDone:YES];
	}
	[pool release];
}

static void TCPServerConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	if (data != NULL) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"连接失败" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
		[alert show];
		[alert release];
		return;
	}
	TCPClientDemoAppDelegate *delegate = (TCPClientDemoAppDelegate *)info;
	[delegate performSelectorInBackground:@selector(readStream) withObject:nil];
	[delegate.connController dismissModalViewControllerAnimated:YES];
	[[NSNotificationCenter defaultCenter] addObserver:delegate.chatController selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:delegate.chatController selector:@selector(keyboardWillHidden:) name:UIKeyboardWillHideNotification object:nil];
}

- (void) doConnect {
	CFSocketContext CTX = {0, self, NULL, NULL, NULL};
	_socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack, TCPServerConnectCallBack, &CTX);
	if (NULL == _socket) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"创建套接字失败" delegate:nil cancelButtonTitle:@"关闭" otherButtonTitles:nil];
		[alert show];
		[alert release];
	}
	struct sockaddr_in addr4;
	memset(&addr4, 0, sizeof(addr4));
	addr4.sin_len = sizeof(addr4);
	addr4.sin_family = AF_INET;
	addr4.sin_port = htons(12345);
	addr4.sin_addr.s_addr = inet_addr([connController.textField.text UTF8String]);
	CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
	
	CFSocketConnectToAddress(_socket, address, -1);
	
	CFRunLoopRef cfrl = CFRunLoopGetCurrent();
	CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
	CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
	CFRelease(source);
}

- (void) sendMessage {
	NSString *stringToSend = [chatController.textField.text stringByAppendingString:@"\n"];
	const char *data = [stringToSend UTF8String];
	send(CFSocketGetNative(_socket), data, strlen(data) + 1, 0);
	NSRange endRange;
	endRange.location = [chatController.textView.text length];
	endRange.length = [stringToSend length];
	chatController.textView.text = [chatController.textView.text stringByAppendingString:[@"me: " stringByAppendingString:stringToSend]];
	[chatController.textView scrollRangeToVisible:endRange];
	chatController.textField.text = @"";
}


@end
