#include <stdio.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <pthread.h>
#include <CoreFoundation/CoreFoundation.h>

CFSocketRef _socket;
uint16_t port = 12345;
CFWriteStreamRef outputStream = NULL;

int main (int argc, const char * argv[]) {
	pthread_attr_t	attr;
	pthread_t		posixThreadID;
	int				returnVal;
	
	// 新建一个线程运行CFSocket相关的run loop
	returnVal = pthread_attr_init(&attr);
	assert(!returnVal);
	returnVal = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
	assert(!returnVal);
	void runLoopInThread();
	int threadError = pthread_create(&posixThreadID, &attr, &runLoopInThread, NULL);
	
	returnVal = pthread_attr_destroy(&attr);
	assert(!returnVal);
	if (threadError != 0) {
		printf("An error occurs during creating a thread.\n");
	}
	
	// 获得用户输入，向客户端发送
	char c;
	UInt8 line[100];
	int i = 0;
	while (c = getchar()) {
		if (c != '\n') {
			line[i++] = c;
		} else if (i != 0){
			line[i++] = '\n';
			line[i] = '\0';
			i = 0;
			if (outputStream != NULL) {
				CFWriteStreamWrite(outputStream, line, strlen((char *)line) + 1);
			} else {
				printf("Cannot send data!\n");
			}
		}
	}
	return 0;
}

void runLoopInThread() {
	int setupSocket();
	int res = setupSocket();
	if (!res) {
		exit(1);
	}
	CFRunLoopRun();
}

void readStream(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
	UInt8 buff[255];
	CFReadStreamRead(stream, buff, 255);
	printf("received: %s", buff);
}

void writeStream (CFWriteStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo) {
	outputStream = stream;
}

void TCPServerAcceptCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	if (kCFSocketAcceptCallBack == type) {
		CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
		uint8_t name[SOCK_MAXADDRLEN];
		socklen_t namelen = sizeof(name);
		if (0 != getpeername(nativeSocketHandle, (struct sockaddr *)name, &namelen)) {
			printf("error %d\n", errno);
			exit(1);
		}
		
		printf("%s connected\n", inet_ntoa(((struct sockaddr_in *)name)->sin_addr));
		CFReadStreamRef iStream;
		CFWriteStreamRef oStream;
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &iStream, &oStream);
		if (iStream && oStream) {
			CFStreamClientContext streamCtxt = {0, NULL, NULL, NULL, NULL};
			if(!CFReadStreamSetClient(iStream, kCFStreamEventHasBytesAvailable, readStream, &streamCtxt)) {
				exit(1);
			}
			if (!CFWriteStreamSetClient(oStream, kCFStreamEventCanAcceptBytes, writeStream, &streamCtxt)) {
				exit(1);
			}
			CFReadStreamScheduleWithRunLoop(iStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
			CFWriteStreamScheduleWithRunLoop(oStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
			CFReadStreamOpen(iStream);
			CFWriteStreamOpen(oStream);
		} else {
			close(nativeSocketHandle);
		}
	}
}

int setupSocket() {
	_socket = CFSocketCreate(kCFAllocatorDefault, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, TCPServerAcceptCallBack, NULL);
	if (NULL == _socket) {
		printf("Cannot create socket!");
		return 0;
	}
	
	int yes = 1;
	setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, (void *)&yes, sizeof(yes));
	
	struct sockaddr_in addr4;
	memset(&addr4, 0, sizeof(addr4));
	addr4.sin_len = sizeof(addr4);
	addr4.sin_family = AF_INET;
	addr4.sin_port = htons(port);
	addr4.sin_addr.s_addr = htonl(INADDR_ANY);
	CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
	
	if (kCFSocketSuccess != CFSocketSetAddress(_socket, address)) {
		printf("Bind to address failed!");
		if (_socket) CFRelease(_socket);
		_socket = NULL;
		return 0;
	}
	
	UInt8 buffer[SOCK_MAXADDRLEN];
	CFDataRef addr = CFSocketCopyAddress(_socket);
	CFDataGetBytes(addr, CFRangeMake(0,CFDataGetLength(addr)), buffer);
	memcpy(&addr4, buffer, CFDataGetLength(addr));
	printf("Server started!\n");
	
	CFRunLoopRef cfrl = CFRunLoopGetCurrent();
	CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
	CFRunLoopAddSource(cfrl, source, kCFRunLoopCommonModes);
	CFRelease(source);
	
	return 1;
}
