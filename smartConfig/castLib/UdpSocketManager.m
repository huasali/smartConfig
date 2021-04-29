//
//  UdpSocketManager.m
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/7.
//

#import "UdpSocketManager.h"
#import "MutlicastWork.h"
#import "BroadcastWork.h"
#import "CastClient.h"

@interface UdpSocketManager (){
    dispatch_queue_t _unicastQueue;
    dispatch_queue_t _mutlicastQueue;
    dispatch_queue_t _broadcastQueue;
    id _logBlock;
}

@property (nonatomic, strong) UnicastWork *unicastWork;
@property (nonatomic, strong) MutlicastWork *mutlicastWork;
@property (nonatomic, strong) BroadcastWork *broadcastWork;

@end

@implementation UdpSocketManager
static  id _instance = nil;
+ (UdpSocketManager *)manager{
    return [self shareManager];
}
+ (instancetype)shareManager{
    if (_instance == nil) {
        _instance = [[self alloc] init];
    }
    return _instance;
}
+ (id)allocWithZone:(NSZone *)zone{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}
- (UnicastWork *)unicastWork{
    if (!_unicastWork.castClient) {
        CastClient *client = [[CastClient alloc]initWithManager:self title:@"unicast" port:0 dq:_unicastQueue];
        _unicastWork.castClient = client;
    }
    return _unicastWork;
}
- (MutlicastWork *)mutlicastWork{
    if (!_mutlicastWork.castClient) {
        CastClient *client = [[CastClient alloc]initWithManager:self title:@"mutlicast" port:0 dq:_mutlicastQueue];
        _mutlicastWork.castClient = client;
    }
    return _mutlicastWork;
}
- (BroadcastWork *)broadcastWork{
    if (!_broadcastWork.castClient) {
        CastClient *client = [[CastClient alloc]initWithManager:self title:@"broadcast" port:0 dq:_broadcastQueue];
        _broadcastWork.castClient = client;
    }
    return _broadcastWork;
}

- (void)initData:(void(^)(NSString *logString))logBlock{
    if (_logBlock) {
        _logBlock = nil;
    }
    _logBlock = [logBlock copy];
    _unicastQueue   = dispatch_queue_create("com.cast.unicast", DISPATCH_QUEUE_SERIAL);
    _mutlicastQueue = dispatch_queue_create("com.cast.mutlicast", DISPATCH_QUEUE_SERIAL);
    _broadcastQueue = dispatch_queue_create("com.cast.broadcast", DISPATCH_QUEUE_SERIAL);
    _unicastWork   = [[UnicastWork alloc]   initWithManager:self title:@"unicastwork"  dq:_unicastQueue];
    _mutlicastWork = [[MutlicastWork alloc] initWithManager:self title:@"mutlicast"    dq:_unicastQueue];
    _broadcastWork = [[BroadcastWork alloc] initWithManager:self title:@"broadcast"    dq:_unicastQueue];
}
- (void)printLog:(NSString *)logString{
    if (_logBlock) {
        void(^completion)(id object) = [_logBlock copy];
        completion(logString);
    }
}
- (void)sendUnicastString:(NSString *)str host:(NSString *)host port:(int)port{
    [self.unicastWork sendString:str toHost:host port:port];
}
- (void)sendUnicastHexString:(NSString *)hexStr host:(NSString *)host port:(int)port{
    [self.unicastWork sendHexString:hexStr toHost:host port:port];
}
- (void)sendMutlicastDataSSID:(NSString *)ssid  pwd:(NSString *)pwd bssid:(NSString *)bssid key:(NSString *)key timeout:(int)timeout{
    [self.mutlicastWork sendDataSSID:ssid pwd:pwd bssid:bssid key:key timeout:timeout];
}
- (void)sendBroadcastDataSSID:(NSString *)ssid  pwd:(NSString *)pwd key:(NSString *)key timeout:(int)timeout{
    [self.broadcastWork sendData:ssid pwd:pwd key:key timeout:timeout];
}
- (void)stopCast{
    if (_mutlicastWork) {
        [_mutlicastWork abort];
    }
    if (_broadcastWork) {
        [_broadcastWork abort];
    }
}

@end
