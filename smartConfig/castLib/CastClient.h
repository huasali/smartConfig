//
//  CastClient.h
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "UdpSocketManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CastClient : NSObject

@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) uint16_t bindPort;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, assign) uint16_t port;
@property (nonatomic, assign) NSTimeInterval outTime;
@property (nonatomic, assign) int state;

- (instancetype)initWithManager:(id)manager title:(NSString*)title port:(uint16_t)port dq:(dispatch_queue_t)dq;

- (void)sendHexStringData:(NSString *)data toHost:(NSString *)host port:(uint16_t)port;
- (void)sendStringData:(NSString *)data toHost:(NSString *)host port:(uint16_t)port;
- (void)sendData:(NSData *)data toHost:(NSString *)host port:(uint16_t)port;
- (void)destroy;
@end

NS_ASSUME_NONNULL_END
