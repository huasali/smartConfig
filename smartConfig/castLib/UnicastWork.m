//
//  UnicastWork.m
//  smartConfigDemo
//
//  Created by Huasali on 2021/4/7.
//

#import "UnicastWork.h"
#include <arpa/inet.h>
#include <dns.h>
#include <resolv.h>
#include <ifaddrs.h>
#import <openssl/aes.h>

@interface UnicastWork (){
    dispatch_queue_t _unicastQueue;
    UdpSocketManager *_udpManager;
}
@end

@implementation UnicastWork
- (instancetype)initWithManager:(id)manager title:(NSString *)title dq:(dispatch_queue_t)dq{
    if ((self = [super init])){
        _title = title;
        _udpManager = manager;
        _unicastQueue = dq;
    }
    return self;
}
- (void)printLog:(NSString *)logString{
    [_udpManager printLog:logString];
}
- (void)start{
    UdpLog(@"start");
}
- (void)pause{
    UdpLog(@"pause");
}
- (void)resume{
    UdpLog(@"resume");
}
- (void)abort{
    UdpLog(@"abort");
}
- (void)sendHexString:(NSString *)dataStr toHost:(NSString *)host port:(uint16_t)port{
    [_castClient sendHexStringData:dataStr toHost:host port:port];
}
- (void)sendString:(NSString *)dataStr toHost:(NSString *)host port:(uint16_t)port{
    [_castClient sendStringData:dataStr toHost:host port:port];
}
- (void)sendData:(NSData *)data toHost:(NSString *)host port:(uint16_t)port{
    [_castClient sendData:data toHost:host port:port];
}

#pragma mark Tool

- (NSData *)zeroDataWithCount:(int)count{
    Byte codeData[count];
    for (int i = 0; i < count; i++) {
        codeData[i] = 0x00;
    }
    return  [NSData dataWithBytes:codeData length:sizeof(codeData)];
}
- (NSData *)dataFromSubData:(NSData *)data loc:(int)loc length:(int)length{
    if (loc+length > data.length) {
        return nil;
    }
    NSData *tempData = [data subdataWithRange:NSMakeRange(loc,length)];
    return  tempData;
}
- (int)crcData:(NSData *)data{
    uint16_t sumNumber = 0;
    uint16_t resultNumber = 0;
    Byte *dataByte = (Byte *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        sumNumber += dataByte[i];
    }
    resultNumber = sumNumber & (0x3F << 0);
    resultNumber |= (sumNumber & (0x3F << 6)) << 2;
    if (!(resultNumber & 0x00FF)) resultNumber |= 0x0001;
    if (!(resultNumber & 0xFF00)) resultNumber |= 0x0100;
    return resultNumber;
}
- (int)checksum:(NSData *)data{
    int sumNumber = 0;
    uint16_t resultNumber = 0;
    Byte *dataByte = (Byte *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        sumNumber += dataByte[i];
    }
    resultNumber = sumNumber&0xff;
    return resultNumber;
}
- (NSData *)dataWithEncrypt:(NSString *)str type:(int)type key:(NSString *)keyString encode:(BOOL)isEncode{
    if (!str) {
        return  nil;
    }
    if (str.length == 0) {
        return  nil;
    }
    NSData *pwdData = [str dataUsingEncoding:NSASCIIStringEncoding];
    if (type > 1) {
        NSData *keyData = [self dataFromHexString:keyString];
        Byte *byteData = (Byte *)[pwdData bytes];
        NSData *tempResultData = [self gnAesEncryptData:byteData len:(int)pwdData.length keyData:keyData];
        return isEncode?[self encodeChinese:tempResultData]:tempResultData;
    }
    else{
        return isEncode?[self subtractCodeWithData:pwdData]:pwdData;
    }
}
- (NSData *)dataFromChineseStr:(NSString *)str encode:(BOOL)isEncode{
    if (!str) {
        return  nil;
    }
    if ([self isChinese:str]) {
        NSData *strData = [str dataUsingEncoding:NSUTF8StringEncoding];
        return isEncode?[self encodeChinese:strData]:strData;
    }
    else{
        NSData *strData = [str dataUsingEncoding:NSASCIIStringEncoding];
        return isEncode?[self subtractCodeWithData:strData]:strData;
    }
}
- (NSData *)dataFromMacString:(NSString *)macString{
    NSString *jsonString = [macString stringByReplacingOccurrencesOfString:@":" withString:@""];
    jsonString = [jsonString stringByReplacingOccurrencesOfString:@"." withString:@""];
    NSData *tempData = [self dataFromHexString:jsonString];
    return tempData;
}
- (NSData *)dataFromRand:(int)count{
    Byte codeData[count];
    for (int i = 0; i < count; i++) {
        codeData[i] = arc4random()%255 + 1;
    }
    return  [NSData dataWithBytes:codeData length:sizeof(codeData)];
}
- (NSData *)dataAddDataLength:(NSData *)data{
    int length = (int)data.length;
    NSMutableData *lengthData = [NSMutableData dataWithBytes:&length length:1];
    [lengthData appendData:data];
    return  lengthData;
}
- (BOOL)isChinese:(NSString *) str{
    for(int i=0; i< [str length];i++){
        int a = [str characterAtIndex:i];
        if( a > 0x4E00 && a < 0x9FFF){
            return YES;
        }
    }
    return NO;
}
- (NSData *)addCodeWithData:(NSData *)data{
    Byte codeData[data.length];
    Byte *dataByte = (Byte *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        codeData[i] = dataByte[i] + 0x20;
    }
    NSData *tempCodeData = [NSData dataWithBytes:codeData length:sizeof(codeData)];
    return  tempCodeData;
}
- (NSData *)subtractCodeWithData:(NSData *)data{
    Byte codeData[data.length];
    Byte *dataByte = (Byte *)data.bytes;
    for (int i = 0; i < data.length; i++) {
        codeData[i] = dataByte[i] - 0x20;
    }
    NSData *tempCodeData = [NSData dataWithBytes:codeData length:sizeof(codeData)];
    return  tempCodeData;
}
- (NSData *)decodeChinese:(NSData *)data{
    int  bitCount = 6;
    int  dataLength = (int)data.length;
    Byte codeData[dataLength * bitCount];
    int  outLength = dataLength * bitCount /8;
    Byte outData[outLength];
    Byte *dataByte = (Byte *)data.bytes;
    for (int i = 0; i < dataLength; i ++) {
        for (int j = 0; j < bitCount; j++) {
            codeData[i * bitCount + j] = (dataByte[i] >> j) & 0x01;
        }
    }
    for (int i = 0; i < outLength; i++) {
        outData[i] = 0;
        for (int j = 0; j < 8; j ++) {
            outData[i] |= codeData[i * 8 + j] << j;
        }
    }
    NSData *tempCodeData = [NSData dataWithBytes:outData length:sizeof(outData)];
    return  tempCodeData;
}
- (NSData *)encodeChinese:(NSData *)data{
    int  bitCount = 6;
    int  dataLength = (int)data.length;
    Byte codeData[dataLength * bitCount];
    int  outLength = (dataLength * 8 + bitCount - 1) /bitCount;
    Byte outData[outLength];
    Byte *dataByte = (Byte *)data.bytes;
    for (int i = 0; i < dataLength; i ++) {
        for (int j = 0; j < 8; j++) {
            codeData[i * 8 + j] = (dataByte[i] >> j) & 0x01;
        }
    }
    for (int i = 0; i < outLength; i++) {
        outData[i] = 0;
        for (int j = 0; j < bitCount; j ++) {
            outData[i] |= codeData[i * bitCount + j] << j;
        }
    }
    NSData *tempCodeData = [NSData dataWithBytes:outData length:sizeof(outData)];
    return  tempCodeData;
}
- (NSString *)hexStringFromData:(NSData *)data{
  if (data) {
    Byte *byte = (Byte *)[data bytes];
    NSString *string = [NSString new];
    for (int i=0; i<data.length; i++) {
      NSString *tempStr = [NSString stringWithFormat:@"%02X",byte[i]];
      string = [string stringByAppendingString:tempStr];
    }
    return string;
  }
  return @"";
}
- (NSData *)dataFromHexString:(NSString *)string{
  NSString *jsonString = [string stringByReplacingOccurrencesOfString:@" " withString:@""];
  NSMutableData* data = [NSMutableData data];
  int idx;
  for (idx = 0; idx+2 <= jsonString.length; idx+=2) {
    NSRange range = NSMakeRange(idx, 2);
    NSString* hexStr = [jsonString substringWithRange:range];
    NSScanner* scanner = [NSScanner scannerWithString:hexStr];
    unsigned int intValue;
    [scanner scanHexInt:&intValue];
    [data appendBytes:&intValue length:1];
  }
  return data;
}
//加密
- (NSData *)gnAesEncryptData:(uint8_t *)crypt_data len:(int)crypt_len keyData:(NSData *)keydata{
    unsigned char *keyResult=(Byte*)[keydata bytes];
    AES_KEY aes_key;
    unsigned char *outByte = NULL;
    outByte = (unsigned char *)malloc(crypt_len+1);
    memset(outByte, 0, crypt_len+1);
    AES_set_encrypt_key(keyResult, 128, &aes_key);
    int number = 0;
    NSData *ivData = [NSData dataWithBytes:&number length:1];
    unsigned char *ivResult = (Byte*)[ivData bytes];
    NSData *numData = [NSData dataWithBytes:&number length:1];
    int *numResult = (int *)[numData bytes];
    AES_cfb128_encrypt(crypt_data,outByte,crypt_len, &aes_key,ivResult,numResult ,AES_ENCRYPT);
    NSData *Decrydata = [NSData dataWithBytes:outByte length:crypt_len];
    return Decrydata;
}
//解密
- (NSData *)gnAesDecryptData:(uint8_t *)crypt_data len:(int)crypt_len keyData:(NSData *)keydata{
    unsigned char *keyResult=(Byte*)[keydata bytes];
    AES_KEY aes_key;
    unsigned char *outByte = NULL;
    outByte = (unsigned char *)malloc(crypt_len+1);
    memset(outByte, 0, crypt_len+1);
    AES_set_encrypt_key(keyResult, 128, &aes_key);
    int number = 0;
    NSData *ivData = [NSData dataWithBytes:&number length:1];
    unsigned char *ivResult = (Byte*)[ivData bytes];
    NSData *numData = [NSData dataWithBytes:&number length:1];
    int *numResult = (int *)[numData bytes];
    AES_cfb128_encrypt(crypt_data,outByte,crypt_len, &aes_key,ivResult,numResult ,AES_DECRYPT);
    NSData *Decrydata = [NSData dataWithBytes:outByte length:crypt_len];
    return Decrydata;
}

/// @param strInterface @"en0" ip  @"pdp_ip0" cell @"ppp0" vpn
- (NSDictionary *)getIPAddressInfo:(NSString*)strInterface{
    NSMutableDictionary *dicIPInfo = [[NSMutableDictionary alloc] init];
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0){
        temp_addr = interfaces;
        while(temp_addr != NULL){
            if(temp_addr->ifa_addr->sa_family == AF_INET){
                char *interface_name = temp_addr->ifa_name;
                if([[NSString stringWithUTF8String:interface_name] isEqualToString:strInterface]){
                    //接口名称
                    NSString *strInterfaceName = [NSString stringWithUTF8String:interface_name];
                    //ip地址
                    char *ip = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr);
                    NSString *strIP = [NSString stringWithUTF8String:ip];
                    //子网掩码
                    char *submask = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_netmask)->sin_addr);
                    NSString *strSubmask = [NSString stringWithUTF8String:submask];
                    //广播地址
                    char *dstaddr = inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_dstaddr)->sin_addr);
                    NSString *strDstaddr = [NSString stringWithUTF8String:dstaddr];
                    if (strIP) {
                        [dicIPInfo setValue:strIP forKey:@"ip"];
                    }
                    if (strInterfaceName) {
                        [dicIPInfo setValue:strInterfaceName forKey:@"interfacename"];
                    }
                    if (strSubmask) {
                        [dicIPInfo setValue:strSubmask forKey:@"submask"];
                    }
                    if (strDstaddr) {
                        [dicIPInfo setValue:strDstaddr forKey:@"broadcast"];
                    }
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return dicIPInfo;
}

@end
