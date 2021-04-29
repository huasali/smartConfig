//
//  MutlicastWork.m
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/8.
//

#import "MutlicastWork.h"

@interface MutlicastWork (){
    NSTimer *_sendTimer;
    int _sendCount;
    int _maxCount;
    int _timeout;
}

@end

@implementation MutlicastWork


- (void)sendDataSSID:(NSString *)ssid  pwd:(NSString *)pwd bssid:(NSString *)bssid key:(NSString *)key timeout:(int)timeout{
    _sendData = [self dataWtihSSID:[self dataFromChineseStr:ssid encode:false] pwd:[self dataWithEncrypt:pwd type:3 key:key encode:false] bssidData:[self dataFromSubData:[self dataFromMacString:bssid] loc:3 length:3] rand:[self dataFromRand:3]];
    UdpLog(@"sendData = %@",[self hexStringFromData:_sendData]);
    _timeout = timeout*5;
    int length = (int)_sendData.length;
    int total = length/2 + 1;
    if ((length%2) == 0) {
      total--;
    }
    _maxCount = total;
    [self start];
}

- (void)start{
    _sendCount = 0;
    [self startSend];
}
- (void)pause{
    [self endSend];
}
- (void)resume{
    [self startSend];
}
- (void)abort{
    [self endSend];
    _sendCount = 0;
}

- (void)startSend{
    if (!_sendTimer) {
        _sendTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(sendDataAction:) userInfo:nil repeats:YES];
    }
}
- (void)endSend{
    if (_sendTimer) {
        [_sendTimer invalidate];
        _sendTimer = nil;
    }
}

- (void)sendDataAction:(NSTimer *)t{
    NSString *valueString = [self valueFromSendData];
    NSString *ipString = [self ipStringWithData:valueString count:_sendCount];
    [self.castClient sendData:[self zeroDataWithCount:1] toHost:ipString port:60000+_sendCount];
    _sendCount++;
    if (_sendCount >= _maxCount) {
        _sendCount = 0;
    }
    _timeout--;
    if (_timeout <= 0) {
        [self endSend];
    }
}

- (NSString *)ipStringWithData:(NSString *)dataString count:(int)count{
    NSString *ipString = [NSString stringWithFormat:@"239.%d.%@",count,dataString];
    return ipString;
}

- (NSString *)valueFromSendData{
    NSData *tempFstData = [self dataFromSubData:_sendData loc:_sendCount*2 length:1];
    NSData *tempSecData = [self dataFromSubData:_sendData loc:_sendCount*2+1 length:1];
    if (!tempFstData) {
        tempFstData = [self zeroDataWithCount:1];
    }
    if (!tempSecData) {
        tempSecData = [self zeroDataWithCount:1];
    }
    int dataFstNumber  = *(int *)tempFstData.bytes;
    int dataSecNumber  = *(int *)tempSecData.bytes;
    return [NSString stringWithFormat:@"%d.%d",dataFstNumber,dataSecNumber];
}

- (NSData *)dataWtihSSID:(NSData *)ssidData pwd:(NSData *)pwdData bssidData:(NSData *)bssidData rand:(NSData *)randData{
    if (!bssidData) {
        bssidData = [self zeroDataWithCount:3];
        UdpLog(@"[error] bssid is nil");
    }
    Byte packHead[2];
    int pwdLength = 0;
    if (pwdData) {
        pwdLength = (int)pwdData.length + 1;
        packHead[1] = 0xc7;
    }
    else{
        packHead[1] = 0xc6;
    }
    packHead[0] = 6 + ssidData.length + pwdLength + bssidData.length + randData.length;
    NSMutableData *packHeadData = [NSMutableData dataWithBytes:packHead length:sizeof(packHead)];
    if (pwdData) {
        [packHeadData appendData:[self dataAddDataLength:pwdData]];
    }
    [packHeadData appendData:[self dataAddDataLength:randData]];
    [packHeadData appendData:[self dataAddDataLength:ssidData]];
    [packHeadData appendData:[self dataAddDataLength:bssidData]];
    int crc = [self checksum:packHeadData];
    NSData *crcData = [NSData dataWithBytes:&crc length:1];
    [packHeadData appendData:crcData];
    return packHeadData;;
}

@end
