//
//  ViewController.m
//  smartConfig
//
//  Created by Huasali on 2021/4/29.
//

#import "ViewController.h"
#import "UdpSocketManager.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "GNLocationWork.h"

NSString *const EncryptKey  = @"000102030405060708090a0b0c0d0e0f";

@interface ViewController (){
    NSDateFormatter *_dateFormatter;
    GNLocationWork *_locationWork;
    NSString *_ssidString;
    NSString *_bssidString;
    NSString *_pwdString;
}

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *ssidText;
@property (weak, nonatomic) IBOutlet UITextField *pwdText;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _dateFormatter = [[NSDateFormatter alloc]init];
    [_dateFormatter setDateFormat:@"MM-dd hh:mm:ss"];
    __weak typeof(self) weakSelf = self;
    [[UdpSocketManager manager] initData:^(NSString * _Nonnull logString) {
        [weakSelf printLog:logString];
    }];
    _locationWork = [[GNLocationWork alloc] initWithManager:[UdpSocketManager manager] title:@"location" block:^(NSDictionary * _Nonnull locationDic) {
        [weakSelf takeWifiInfo];
    }];
    [_locationWork startUpdateLocation];

}

- (void)printLog:(NSString *)logString{
    NSLog(@"%@",logString);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = [self.textView.text stringByAppendingFormat:@"%@ %@\n",[self->_dateFormatter stringFromDate:[NSDate date]] ,logString];
        if (self.textView.contentSize.height > self.textView.frame.size.height) {
            int offset = self.textView.contentSize.height - self.textView.frame.size.height;
            [self.textView setContentOffset:CGPointMake(0, offset) animated:NO];
        }
    });
}
- (void)takeWifiInfo{
    self.ssidText.text = [self currentWifiSSID];
    _bssidString = [self currentWifiBSSID];
    _pwdString = self.pwdText.text;
    _ssidString = self.ssidText.text;
    UdpLog(@"ssid:%@",_ssidString);
    UdpLog(@"pwd:%@",_pwdString);
    UdpLog(@"bssid:%@",_bssidString);
    
}

- (IBAction)unicastAction:(id)sender {
    [[UdpSocketManager manager] sendUnicastString:self.ssidText.text host:@"192.168.3.255" port:5000];
}
- (IBAction)multiAction:(id)sender {
    [self takeWifiInfo];
    [[UdpSocketManager manager] sendMutlicastDataSSID:_ssidString pwd:_pwdString bssid:_bssidString?:@"" key:EncryptKey timeout:600];
}
- (IBAction)broadAction:(id)sender {
    [self takeWifiInfo];
    [[UdpSocketManager manager] sendBroadcastDataSSID:_ssidString pwd:_pwdString key:EncryptKey timeout:600];
}
- (IBAction)allAction:(id)sender {
    [self takeWifiInfo];
    [[UdpSocketManager manager] sendMutlicastDataSSID:_ssidString pwd:_pwdString bssid:_bssidString?:@"" key:EncryptKey timeout:60];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [[UdpSocketManager manager] sendBroadcastDataSSID:self->_ssidString pwd:self->_pwdString key:EncryptKey timeout:50];
    });
}
- (IBAction)saveAction:(id)sender {
    UdpLog(@"save data");
    NSString *logPath = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/%@.log",[self->_dateFormatter stringFromDate:[NSDate date]]]];
    NSError *error;
    BOOL flag = [self.textView.text writeToFile:logPath atomically:true encoding:NSUTF8StringEncoding error:&error];
    if (flag) {
        UdpLog(@"save success path:%@",logPath);
    }
    else{
        UdpLog(@"save failed : %@",error);
    }
}
- (IBAction)stopAction:(id)sender {
    [[UdpSocketManager manager] stopCast];
}

- (NSString *)currentWifiSSID{
  NSString *ssid = @"";
  NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
  for (NSString *ifnam in ifs) {
    NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
    if (info[@"SSID"]) {
      ssid = info[@"SSID"];
    }
  }
  return ssid;
}

- (NSString *)currentWifiBSSID{
  NSString *bssid = @"";
  NSArray *ifs = (__bridge_transfer id)CNCopySupportedInterfaces();
  for (NSString *ifnam in ifs) {
    NSDictionary *info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
    if (info[@"BSSID"]) {
      bssid = info[@"BSSID"];
    }
  }
  return bssid;
}

@end
