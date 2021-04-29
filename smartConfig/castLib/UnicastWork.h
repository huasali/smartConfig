//
//  UnicastWork.h
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/7.
//

#import <Foundation/Foundation.h>
#import "CastClient.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    WorkStateStarting,
    WorkStatePause,
    WorkStateCompleted,
    WorkStateAborted,
} CastWorkState;

@interface UnicastWork : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) CastWorkState state;
@property (nonatomic, strong) CastClient *castClient;

- (instancetype)initWithManager:(id)manager title:(NSString *)title dq:(dispatch_queue_t)dq;
- (void)sendHexString:(NSString *)dataStr toHost:(NSString *)host port:(uint16_t)port;
- (void)sendString:(NSString *)dataStr toHost:(NSString *)host port:(uint16_t)port;
- (void)sendData:(NSData *)data toHost:(NSString *)host port:(uint16_t)port;

- (void)start;
- (void)pause;
- (void)resume;
- (void)abort;
- (void)printLog:(NSString *)logString;

- (NSDictionary *)getIPAddressInfo:(NSString*)strInterface;
- (NSString *)hexStringFromData:(NSData *)data;
- (NSData *)zeroDataWithCount:(int)count;
- (NSData *)dataFromSubData:(NSData *)data loc:(int)loc length:(int)length;
- (NSData *)dataFromChineseStr:(NSString *)str encode:(BOOL)isEncode;
- (NSData *)dataFromMacString:(NSString *)macString;
- (NSData *)dataFromRand:(int)count;
- (NSData *)dataAddDataLength:(NSData *)data;
- (NSData *)dataWithEncrypt:(NSString *)str type:(int)type key:(NSString *)keyString encode:(BOOL)isEncode;

- (int)crcData:(NSData *)data;
- (int)checksum:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
