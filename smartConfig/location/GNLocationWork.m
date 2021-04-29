//
//  GNLocationWork.m
//  GNBlueToothLibrary
//
//  Created by Huasali on 2021/3/18.
//

#import "GNLocationWork.h"
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "UdpSocketManager.h"

@interface GNLocationWork()<CLLocationManagerDelegate>{
    CLLocationManager *_CLLmanager;
    UdpSocketManager *_udpManager;
    id _locationBlock;
}

@end

@implementation GNLocationWork

- (instancetype)initWithManager:(id)manager title:(NSString*)title block:(void(^)(NSDictionary *locationDic))locationBlock{
    if ((self = [super init])){
        _title      = title;
        _udpManager = manager;
        _locationBlock = [locationBlock copy];
    }
    return self;
}

+ (void)saveDeviceLocation:(NSDictionary *)locationDic{
    if (!locationDic) {
        return;
    }
    NSNumber *lat = [locationDic valueForKey:@"latitude"];
    NSNumber *lon = [locationDic valueForKey:@"longitude"];
    if (lat&&lon) {
      [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@",lat] forKey:@"latitude"];
      [[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%@",lon] forKey:@"longitude"];
    }
}
- (void)startUpdateLocation{
    UdpLog(@"startUpdateLocation %d",[CLLocationManager authorizationStatus]);
    if ([CLLocationManager locationServicesEnabled] && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse  || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways)) {
        [self updateNewLocation];
    }
    else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined){
        [self requestWhenInUseAuthorization];
    }
}

- (void)requestWhenInUseAuthorization{
    UdpLog(@"request");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->_CLLmanager) {
            self->_CLLmanager = [[CLLocationManager alloc] init];
            self->_CLLmanager.delegate = self;
        }
        [self->_CLLmanager requestWhenInUseAuthorization];
    });
}
- (void)updateNewLocation{
    UdpLog(@"update");
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self->_CLLmanager) {
            self->_CLLmanager = [[CLLocationManager alloc] init];
            self->_CLLmanager.delegate = self;;
        }
        [self->_CLLmanager startUpdatingLocation];
    });
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    if(status == kCLAuthorizationStatusNotDetermined){
        UdpLog(@"NotDetermined");
        [self requestWhenInUseAuthorization];
    }
    else if(status == kCLAuthorizationStatusAuthorizedWhenInUse||status == kCLAuthorizationStatusAuthorizedAlways){
        UdpLog(@"AuthorizedAlways");
        [self updateNewLocation];
    }
}
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations API_AVAILABLE(ios(6.0), macos(10.9)){
    [manager stopUpdatingLocation];
    CLLocation *lastLocation = [locations lastObject];
    if (lastLocation) {
        UdpLog(@"Location lat:%f lon:%f",lastLocation.coordinate.latitude,lastLocation.coordinate.longitude);
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:lastLocation.coordinate.latitude] forKey:@"latitude"];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithDouble:lastLocation.coordinate.longitude] forKey:@"longitude"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (_locationBlock) {
            void(^completion)(id object) = [_locationBlock copy];
            completion(@{@"latitude":[NSNumber numberWithDouble:lastLocation.coordinate.latitude],@"longitude":[NSNumber numberWithDouble:lastLocation.coordinate.longitude]});
        }
    }
}

- (void)printLog:(NSString *)logString{
    [_udpManager printLog:logString];
}


@end

