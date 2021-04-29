//
//  AppDelegate.m
//  smartConfig
//
//  Created by Huasali on 2021/4/29.
//

#import "AppDelegate.h"
#import "AFNetworkReachabilityManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self startNetWork];//触发网络权限
    return YES;
}

- (void)startNetWork{
    AFNetworkReachabilityManager *mgr = [AFNetworkReachabilityManager sharedManager];
        [mgr setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            switch (status) {
                case AFNetworkReachabilityStatusUnknown:
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                    NSLog(@"[network]:NotReachable");
                    break;
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    NSLog(@"[network]:WiFi");
                    break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                    NSLog(@"[network]:WWAN");
                    break;
                default:
                    break;
            }
        }];
        [mgr startMonitoring];
}

#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
