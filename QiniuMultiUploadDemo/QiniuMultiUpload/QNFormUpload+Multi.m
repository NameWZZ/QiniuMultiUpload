//
//  QNFormUpload+Multi.m
//  QiniuMultiUploadDemo
//
//  Created by namewzz on 2019/10/12.
//  Copyright © 2019 namewzz. All rights reserved.
//

#import "QNFormUpload+Multi.h"
#import "QNCrc32.h"
#import "QiniuMultiUploadManager.h"

@implementation QNFormUpload (Multi)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
//重写put方法
- (void)put {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    
    NSString *_key = [self getvalueWithKey:@"key"];
    
    NSString *fileName = _key;
    if (_key) {
        
        if (![QiniuMultiUploadManager sharedManager].fileKeyEnabled) {
            fileName = @"?";
        }else{
            parameters[@"key"] = _key;
        }
    } else {
        fileName = @"?";
    }
    QNUpToken *_token = [self getvalueWithKey:@"token"];
    QNUploadOption *_option = [self getvalueWithKey:@"option"];
    __block float _previousPercent = [[self getvalueWithKey:@"previousPercent"] doubleValue];
    NSData *_data = [self getvalueWithKey:@"data"];
    QNConfiguration *_config = [self getvalueWithKey:@"config"];
    QNUpCompletionHandler _complete = [self getvalueWithKey:@"complete"];
    id<QNHttpDelegate> _httpManager = [self getvalueWithKey:@"httpManager"];
    NSString *_access = [self getvalueWithKey:@"access"];
    
    
    parameters[@"token"] = _token.token;
    [parameters addEntriesFromDictionary:_option.params];
    parameters[@"crc32"] = [NSString stringWithFormat:@"%u", (unsigned int)[QNCrc32 data:_data]];
    QNInternalProgressBlock p = ^(long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        float percent = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
        if (percent > 0.95) {
            percent = 0.95;
        }
        if (percent > _previousPercent) {
            _previousPercent = percent;
        } else {
            percent = _previousPercent;
        }
        _option.progressHandler(_key, percent);
    };
    __block NSString *upHost = [_config.zone up:_token isHttps:_config.useHttps frozenDomain:nil];
    QNCompleteBlock complete = ^(QNResponseInfo *info, NSDictionary *resp) {
        if (info.isOK) {
            _option.progressHandler(_key, 1.0);
        }
        if (info.isOK || !info.couldRetry) {
            _complete(info, _key, resp);
            return;
        }
        if (_option.cancellationSignal()) {
            _complete([QNResponseInfo cancel], _key, nil);
            return;
        }
        __block NSString *nextHost = upHost;
        if (info.isConnectionBroken || info.needSwitchServer) {
            nextHost = [_config.zone up:_token isHttps:_config.useHttps frozenDomain:nextHost];
        }
        QNCompleteBlock retriedComplete = ^(QNResponseInfo *info, NSDictionary *resp) {
            if (info.isOK) {
                _option.progressHandler(_key, 1.0);
            }
            if (info.isOK || !info.couldRetry) {
                _complete(info, _key, resp);
                return;
            }
            if (_option.cancellationSignal()) {
                _complete([QNResponseInfo cancel], _key, nil);
                return;
            }
            NSString *thirdHost = nextHost;
            if (info.isConnectionBroken || info.needSwitchServer) {
                thirdHost = [_config.zone up:_token isHttps:_config.useHttps frozenDomain:nextHost];
            }
            QNCompleteBlock thirdComplete = ^(QNResponseInfo *info, NSDictionary *resp) {
                if (info.isOK) {
                    _option.progressHandler(_key, 1.0);
                }
                _complete(info, _key, resp);
            };
            [_httpManager multipartPost:thirdHost
                               withData:_data
                             withParams:parameters
                           withFileName:fileName
                           withMimeType:_option.mimeType
                      withCompleteBlock:thirdComplete
                      withProgressBlock:p
                        withCancelBlock:_option.cancellationSignal
                             withAccess:_access];
        };
        [_httpManager multipartPost:nextHost
                           withData:_data
                         withParams:parameters
                       withFileName:fileName
                       withMimeType:_option.mimeType
                  withCompleteBlock:retriedComplete
                  withProgressBlock:p
                    withCancelBlock:_option.cancellationSignal
                         withAccess:_access];
    };
    [_httpManager multipartPost:upHost
                       withData:_data
                     withParams:parameters
                   withFileName:fileName
                   withMimeType:_option.mimeType
              withCompleteBlock:complete
              withProgressBlock:p
                withCancelBlock:_option.cancellationSignal
                     withAccess:_access];
}
#pragma clang diagnostic pop

-(id)getvalueWithKey:(NSString*)key{
    
    return [self valueForKey:key];
}
-(void)setkey:(NSString*)key value:(id)value{
    if (!value) {
        return;
    }
    [self setValue:value forKey:key];
}


@end
