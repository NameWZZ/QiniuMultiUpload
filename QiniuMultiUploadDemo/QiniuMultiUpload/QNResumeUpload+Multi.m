//
//  QNResumeUpload+Multi.m
//  QiniuMultiUploadDemo
//
//  Created by namewzz on 2019/10/12.
//  Copyright © 2019 namewzz. All rights reserved.
//

#import "QNResumeUpload+Multi.h"
#import <Qiniu/QNUrlSafeBase64.h>
#import <Qiniu/QNUploadOption.h>
#import "QiniuMultiUploadManager.h"

@implementation QNResumeUpload (Multi)

- (void)makeFile:(NSString *)uphost
        complete:(QNCompleteBlock)complete {
    QNUploadOption *option = [self valueForKey:@"option"];
    UInt32 size = [[self valueForKey:@"size"] intValue];
    NSString *key = [self valueForKey:@"key"];
    NSMutableArray *contexts = [self valueForKey:@"contexts"];
    
    
    NSString *mime = [[NSString alloc] initWithFormat:@"/mimeType/%@", [QNUrlSafeBase64 encodeString:option.mimeType]];
    
    __block NSString *url = [[NSString alloc] initWithFormat:@"%@/mkfile/%u%@", uphost, (unsigned int)size, mime];
    if (![QiniuMultiUploadManager sharedManager].fileKeyEnabled) {
        key = nil;
    }
    if (key != nil) {
        NSString *keyStr = [[NSString alloc] initWithFormat:@"/key/%@", [QNUrlSafeBase64 encodeString:key]];
        url = [NSString stringWithFormat:@"%@%@", url, keyStr];
    }
    
    [option.params enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *obj, BOOL *stop) {
        url = [NSString stringWithFormat:@"%@/%@/%@", url, key, [QNUrlSafeBase64 encodeString:obj]];
    }];
    
    //添加路径
    NSString *fname = [[NSString alloc] initWithFormat:@"/fname/%@", [QNUrlSafeBase64 encodeString:[self fileBaseName]]];
    url = [NSString stringWithFormat:@"%@%@", url, fname];
    
    NSMutableData *postData = [NSMutableData data];
    NSString *bodyStr = [contexts componentsJoinedByString:@","];
    [postData appendData:[bodyStr dataUsingEncoding:NSUTF8StringEncoding]];
    [self post:url withData:postData withCompleteBlock:complete withProgressBlock:nil];
}



#pragma mark - 处理文件路径
- (NSString *)fileBaseName {
    id<QNFileDelegate> _file = [self valueForKey:@"file"];
    return [[_file path] lastPathComponent];
}

- (void)post:(NSString *)url
    withData:(NSData *)data
withCompleteBlock:(QNCompleteBlock)completeBlock
withProgressBlock:(QNInternalProgressBlock)progressBlock {
    id<QNHttpDelegate> _httpManager = [self valueForKey:@"httpManager"];
    NSDictionary *_headers = [self valueForKey:@"headers"];
    QNUploadOption *_option = [self valueForKey:@"option"];
    NSString *_access = [self valueForKey:@"access"];
    
    [_httpManager post:url withData:data withParams:nil withHeaders:_headers withCompleteBlock:completeBlock withProgressBlock:progressBlock withCancelBlock:_option.cancellationSignal withAccess:_access];
}

@end
