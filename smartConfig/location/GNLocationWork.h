//
//  GNLocationWork.h
//  GNBlueToothLibrary
//
//  Created by Huasali on 2021/3/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GNLocationWork : NSObject

@property (nonatomic, strong) NSString *title;

- (instancetype)initWithManager:(id)manager title:(NSString*)title block:(void(^)(NSDictionary *locationDic))locationBlock;
/// 定位
- (void)startUpdateLocation;

/// 设置经纬度
/// @param locationDic @{@"latitude":@"",@"latitude":@""}
+ (void)saveDeviceLocation:(NSDictionary *)locationDic;

@end

NS_ASSUME_NONNULL_END
