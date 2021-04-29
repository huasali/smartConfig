//
//  CastClient.m
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/8.
//

#import "CastClient.h"
#import "GCDAsyncUdpSocket.h"
#import <arpa/inet.h>
#import <fcntl.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <net/if.h>
#import <sys/socket.h>
#import <sys/types.h>

@interface CastClient ()<GCDAsyncUdpSocketDelegate>{
    GCDAsyncUdpSocket *_castSocket;
    dispatch_queue_t _castQueue;
    UdpSocketManager *_udpManager;
    long _sendTag;
}

@end
@implementation CastClient

- (instancetype)initWithManager:(id)manager title:(NSString*)title port:(uint16_t)port dq:(dispatch_queue_t)dq{
    if ((self = [super init])){
        _castQueue  = dq;
        _title      = title;
        _udpManager = manager;
        _state      = 0;
        NSError *error;
        _castSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:_castQueue];
        if (![_castSocket bindToPort:port error:&error]) {
            UdpLog(@"bindToPort error:%@",error);
        }
//        if (![_castSocket joinMulticastGroup:@"239.0.0.1" error:&error]) {
//            UdpLog(@"joinMulticastGroup error:%@",error);
//        }
        if (![_castSocket enableBroadcast:YES error:&error]) {
            UdpLog(@"enableBroadcast error:%@",error);
        }
        if (![_castSocket beginReceiving:&error]) {
            UdpLog(@"beginReceiving error:%@",error);
        }
//        [self setTTL];
    }
    return self;
}

- (void)setTTL{
    __block typeof(self) bself = self;
       [_castSocket performBlock:^{
           char ttl = 16;//默认为1
           int ret = 0;
           int socketFd = [bself->_castSocket socketFD];
           ret = setsockopt(socketFd, IPPROTO_IP, IP_MULTICAST_TTL, (char *)&ttl, sizeof(ttl));
           if (ret != 0) {
               [self->_castSocket close];
               self->_castSocket = nil;
               };
        }];
}
- (void)printLog:(NSString *)logString{
    [_udpManager printLog:logString];
}
- (void)destroy{
    _castSocket = nil;
}
- (void)sendHexStringData:(NSString *)data toHost:(NSString *)host port:(uint16_t)port{
    [self sendData:[self dataFromHexString:data] toHost:host port:port];
}
- (void)sendStringData:(NSString *)data toHost:(NSString *)host port:(uint16_t)port{
    [self sendData:[data dataUsingEncoding:NSUTF8StringEncoding] toHost:host port:port];
}
- (void)sendData:(NSData *)data toHost:(NSString *)host port:(uint16_t)port{
    UdpLog(@"%d --> %@:%d tag:%ld data(%d)",_castSocket.localPort,host,port,data.hash + port,(int)data.length);
    [_castSocket sendData:data toHost:host port:port withTimeout:-1 tag:data.hash + port];
}

#pragma mark UDPdelegate

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address{
    UdpLog(@"ConnectToAddress");
    self.state = 1;
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError * _Nullable)error{
    UdpLog(@"NotConnect");
    self.state = 2;
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
//    UdpLog(@"send success %ld",tag);
    self.state = 3;
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError * _Nullable)error{
    UdpLog(@"send failed %ld error:%@",tag,error);
    self.state = 4;
}
- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
                                             fromAddress:(NSData *)address
withFilterContext:(nullable id)filterContext{
    UdpLog(@"didReceiveData:%@",data);
    self.state = 5;
}
- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError  * _Nullable)error{
    UdpLog(@"error:%@",error);
    self.state = 6;
}
#pragma  mark Tool

- (NSString *)hexStringFromData:(NSData *)data{
  if (data) {
    Byte *byte = (Byte *)[data bytes];
    NSString *string = [NSString new];
    for (int i=0; i<data.length; i++) {
      NSString *tempStr = [NSString stringWithFormat:@"%02X",byte[i]];
      string = [string stringByAppendingString:tempStr];
    }
    return string;
  }
  return @"";
}
- (NSData *)dataFromHexString:(NSString *)string{
  NSString *jsonString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
  NSMutableData* data = [NSMutableData data];
  int idx;
  for (idx = 0; idx+2 <= jsonString.length; idx+=2) {
    NSRange range = NSMakeRange(idx, 2);
    NSString* hexStr = [jsonString substringWithRange:range];
    NSScanner* scanner = [NSScanner scannerWithString:hexStr];
    unsigned int intValue;
    [scanner scanHexInt:&intValue];
    [data appendBytes:&intValue length:1];
  }
  return data;
}

@end
