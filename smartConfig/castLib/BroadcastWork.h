//
//  BroadcastWork.h
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "UnicastWork.h"

NS_ASSUME_NONNULL_BEGIN

@interface BroadcastWork : UnicastWork

@property (nonatomic, strong) NSData *sendData;
- (void)sendData:(NSString *)ssid pwd:(NSString *)pwd key:(NSString *)key timeout:(int)timeout;

@end

NS_ASSUME_NONNULL_END
