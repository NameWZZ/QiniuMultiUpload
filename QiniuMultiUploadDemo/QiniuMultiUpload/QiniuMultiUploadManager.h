//
//  QiniuMultiUploadManager.h
//  QiniuMultiUploadDemo
//
//  Created by namewzz on 2019/10/12.
//  Copyright © 2019 namewzz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Qiniu/QiniuSDK.h>
#import "MultiMediaObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface QiniuMultiUploadManager : NSObject

+ (instancetype)sharedManager;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

@property (nonatomic, copy) NSString *qiuniuToken;

/**
 图片最小值。默认：1M（大于1M触发压缩）
 */
@property (nonatomic, assign) double imageMinSize;

/**
 图片压缩系数，默认：0.8
 */
@property (nonatomic, assign) double imageQuality;

/**
 上传文件名是否自定义 默认：NO（NO，七牛自动生成hash值作为文件名，且文件名无后缀）
 */
@property (nonatomic, assign) BOOL fileKeyEnabled;

- (QNUploadOption *)uploadFiles:(NSArray *)files
         qiniuToken:(NSString *)qiniuToken
           progress:(void (^)(double progress))progressHandle
             sucess:(void (^)(NSDictionary *resp, NSArray *sortValueArray))sucessBlock
            failure:(void (^)(NSError *error, NSArray *failureArray))failureBlock;

/**
 取消上传
 
 @param option QNUploadOption
 */
- (void)cancleWithOption:(QNUploadOption *)option;

@end

NS_ASSUME_NONNULL_END
