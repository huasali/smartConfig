//
//  BroadcastWork.m
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/8.
//

#import "BroadcastWork.h"

@interface BroadcastWork (){
    NSTimer *_sendTimer;
    int _sendCount;
    int _maxCount;
    int _timeout;
    NSString *_broadcastIP;
}
@end

@implementation BroadcastWork

- (void)sendData:(NSString *)ssid pwd:(NSString *)pwd key:(NSString *)key timeout:(int)timeout{
    _sendData = [self dataWtihSSid:[self dataFromChineseStr:ssid encode:true] pwd:[self dataWithEncrypt:pwd type:3 key:key encode:true]];
    UdpLog(@"sendData = %@",[self hexStringFromData:_sendData]);
    _timeout = timeout*5;
    int length = (int)_sendData.length;
    int total = length/8 + 1;
    if ((length%8) == 0) {
      total--;
    }
    _maxCount = length + total*2;
    [self start];
}

- (void)start{
    _sendCount = 0;
    NSDictionary *ipInfo  =[self getIPAddressInfo:@"en0"];
    if (ipInfo[@"broadcast"]) {
        _broadcastIP = ipInfo[@"broadcast"];
        [self startSend];
    }
    else{
        [self abort];
    }
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
    int value = [self valueFromSendData];
    [self.castClient sendData:[self zeroDataWithCount:value] toHost:_broadcastIP port:60000+_sendCount];
    _sendCount++;
    if (_sendCount > _maxCount) {
        _sendCount = 1;
    }
    _timeout--;
    if (_timeout <= 0) {
        [self endSend];
    }
}
- (int)valueFromSendData{
    if (_sendCount <= 2) {
        return  0x480;
    }
    int value = _sendCount%10;
    int count = (_sendCount - 1)/10;
    if (value > 0&&value <= 2) {
        return  0x480 + count;
    }
    else{
        if (value == 0) {
            value = 10;
        }
        NSData *tempData = [self dataFromSubData:_sendData loc:(value - 3) + count*8 length:1];
        int dataValue = *(int *)tempData.bytes;
        if (tempData) {
            return (dataValue&0x7f) + ((value - 1)<<7);
        }
    }
    return  0;;
}

- (NSData *)dataWtihSSid:(NSData *)ssidData pwd:(NSData *)pwdData{
    Byte packHead[4];
    int pwdLength = 0;
    if (pwdData) {
        pwdLength = (int)pwdData.length;
    }
    packHead[0] = 6 + ssidData.length + pwdLength;
    packHead[1] = 0x0f;
    packHead[2] = ssidData.length;
    packHead[3] = pwdLength;
    NSMutableData *packHeadData = [NSMutableData dataWithBytes:packHead length:sizeof(packHead)];
    [packHeadData appendData:ssidData];
    if (pwdData) {
        [packHeadData appendData:pwdData];
    }
    int crc = [self crcData:packHeadData];
    Byte crcByte[2];
    crcByte[0] = (crc>>8)&0xff;
    crcByte[1] = crc&0xff;
    NSData *crcData = [NSData dataWithBytes:crcByte length:2];
    [packHeadData appendData:crcData];
    return packHeadData;;
}
@end
