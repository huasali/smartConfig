//
//  UdpSocketManager.h
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/7.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#define UdpLog(fmt, ...) [self printLog:[NSString stringWithFormat:(@"[app][%@]:"fmt),[self title]?:@"UDP",##__VA_ARGS__]];

@interface UdpSocketManager : NSObject
+ (UdpSocketManager *)manager;

- (void)initData:(void(^)(NSString *logString))logBlock;
- (void)printLog:(NSString *)logString;

- (void)sendUnicastString:(NSString *)str host:(NSString *)host port:(int)port;
- (void)sendUnicastHexString:(NSString *)hexStr host:(NSString *)host port:(int)port;

- (void)sendMutlicastDataSSID:(NSString *)ssid  pwd:(NSString *)pwd bssid:(NSString *)bssid key:(NSString *)key timeout:(int)timeout;
- (void)sendBroadcastDataSSID:(NSString *)ssid  pwd:(NSString *)pwd key:(NSString *)key timeout:(int)timeout;
- (void)stopCast;

@end

NS_ASSUME_NONNULL_END
