//
//  MultiMediaObject.h
//  QiniuMultiUploadDemo
//
//  Created by namewzz on 2019/10/13.
//  Copyright © 2019 namewzz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MediaObjectType) {
    ///相册图片类型
    MediaObjectTypeImage = 0,
    ///视频类型
    MediaObjectTypeVideo = 1,
    ///缓存UIImage类型->启用self.image上传使用
    MediaObjectTypeUIImage = 2,
    ///语音
    MediaObjectTypeVoice = 3,
};

@interface MultiMediaObject : NSObject

/**
 相册选择的数据(图片/视频)
 */
@property (nonatomic, assign) PHAsset *asset;


/**
 addressAsset的内存地址
 */
@property (nonatomic, strong) NSString *addressAsset;

/**
 缓存图片
 */
@property (nonatomic, strong) UIImage *image;

/**
 网络展示数据 ：NSString/NSURL
 */
@property (nonatomic, strong) id netWorkObjUrl;

/**
 数据类型
 */
@property (nonatomic, assign) MediaObjectType mediaObjectType;

@end

NS_ASSUME_NONNULL_END
