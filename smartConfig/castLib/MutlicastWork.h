//
//  MutlicastWork.h
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/8.
//

#import <Foundation/Foundation.h>
#import "UnicastWork.h"

NS_ASSUME_NONNULL_BEGIN

@interface MutlicastWork : UnicastWork

@property (nonatomic, strong) NSData *sendData;
- (void)sendDataSSID:(NSString *)ssid  pwd:(NSString *)pwd bssid:(NSString *)bssid key:(NSString *)key timeout:(int)timeout;

@end

NS_ASSUME_NONNULL_END
