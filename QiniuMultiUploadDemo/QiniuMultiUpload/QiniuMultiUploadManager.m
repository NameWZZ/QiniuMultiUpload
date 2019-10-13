//
//  QiniuMultiUploadManager.m
//  QiniuMultiUploadDemo
//
//  Created by namewzz on 2019/10/12.
//  Copyright © 2019 namewzz. All rights reserved.
//

#import "QiniuMultiUploadManager.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface QiniuMultiUploadManager ()

@property (nonatomic, weak) QNUploadOption *cancleOption;

@property (nonatomic, strong) QNUploadManager *uploadManager;

@end

#ifdef DEBUG
#define NSDLog(FORMAT, ...) fprintf(stderr,"%s:%d\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
#define NSDLog(...)
#endif

@implementation QiniuMultiUploadManager

- (instancetype)_init {
    self = [super init];
    if (!self) {
        return nil;
    }
    _fileKeyEnabled = NO;
    _imageMinSize = 1.0;
    _imageQuality = 0.8;
    
    return self;
}

+ (instancetype)sharedManager {
    static QiniuMultiUploadManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc]_init];
    });
    return manager;
}

- (QNUploadOption *)uploadFiles:(NSArray *)files
         qiniuToken:(nonnull NSString *)qiniuToken
           progress:(void (^)(double progress))progressHandle
             sucess:(void (^)(NSDictionary * resp, NSArray *sortValueArray))sucessBlock
            failure:(void (^)(NSError *error, NSArray *failureArray))failureBlock {
    
    if (![qiniuToken isKindOfClass:[NSString class]]||!qiniuToken.length) {
        NSAssert(NO, @"请检查七牛上传token");
    }
    ///上传开启屏幕常亮
    if ([NSThread isMainThread]) {
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        });
    }
    
    _uploadManager = [QNUploadManager sharedInstanceWithConfiguration:nil];
    
    NSMutableArray *uploadFiles = [files mutableCopy];
    
    NSMutableDictionary *progresDic = [@{} mutableCopy];
    progresDic[@"all_progress"] = @(0);
    NSInteger uploadFilesCount = uploadFiles.count;
    
    __weak typeof(self) weakSelf = self;
    __block QNUploadOption *option = [[QNUploadOption alloc]initWithMime:nil progressHandler:^(NSString *key, float percent) {
        
        NSDLog(@"key==%@  percent===%f", key, percent);
        if (key) {
            NSArray *keys = progresDic.allKeys;
            
            if ([keys indexOfObject:key] == NSNotFound) {
                progresDic[key] = @(percent);
                float allProgress = [[progresDic objectForKey:@"all_progress"] doubleValue];
                allProgress = allProgress + percent;
                progresDic[@"all_progress"] = @(allProgress);
                NSDLog(@"allprogress===%f",allProgress);
                if (progressHandle) {
                    if ([NSThread isMainThread]) {
                        progressHandle(allProgress/(float)uploadFilesCount);
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            progressHandle(allProgress/(float)uploadFilesCount);
                        });
                    }
                }
            }else{
                
                float progress = [[progresDic objectForKey:key] doubleValue];
                
                float allProgress = [[progresDic objectForKey:@"all_progress"] doubleValue];
                allProgress = allProgress - progress + percent;
                progresDic[key] = @(percent);
                progresDic[@"all_progress"] = @(allProgress);
                NSDLog(@"allprogress===%f",allProgress);
                if (progressHandle) {
                    if ([NSThread isMainThread]) {
                        progressHandle(allProgress/(float)uploadFilesCount);
                    }else{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            progressHandle(allProgress/(float)uploadFilesCount);
                        });
                    }
                }
            }
        }
        
    } params:nil checkCrc:NO cancellationSignal:^BOOL{
        if ([option isEqual:weakSelf.cancleOption]) {
            return YES;
        }
        return NO;
    }];
    
    
    __block NSInteger allFilesCount = uploadFilesCount;
    NSMutableDictionary *result = [@{} mutableCopy];
    
    NSMutableArray *sortValueArray = [@[] mutableCopy];
    NSMutableArray *failureArray = [@[] mutableCopy];
    
    for (NSInteger i = 0; i < uploadFiles.count; i++) {
        id obj = uploadFiles[i];
        NSString *filekey = @(i).stringValue;
        
        [self _uploadWithObj:obj qiniuToken:qiniuToken key:filekey option:option assetUseQuality:YES complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
            if (resp == nil) {
                [failureArray addObject:key];
                allFilesCount = allFilesCount-1;
                if (allFilesCount == 0) {
                    failureBlock(info.error,failureArray);
                }
                return;
            }
            if (resp.count) {
                [result setObject:[resp objectForKey:@"key"] forKey:key];
            }
            
            allFilesCount = allFilesCount - 1;
            if (allFilesCount == 0) {
                NSArray *keys = result.allKeys;
                
                for (NSInteger index = 0; index < uploadFiles.count; index++) {
                    NSString *filekey = @(index).stringValue;
                    if ([keys indexOfObject:filekey] != NSNotFound) {
                        id value = [result objectForKey:filekey];
                        if (value) {
                            [sortValueArray addObject:value];
                        }
                    }
                }
                
                if ([NSThread isMainThread]) {
                    [UIApplication sharedApplication].idleTimerDisabled = NO;
                }else{
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication sharedApplication].idleTimerDisabled = NO;
                    });
                }
                if (sucessBlock) {
                    sucessBlock(result,sortValueArray);
                }
            }
            
        }];
        
    }
    
    return option;
    
}


- (void)cancleWithOption:(QNUploadOption *)option {
    _cancleOption = option;
}

- (void)_uploadWithObj:(id)obj
           qiniuToken:(NSString *)qiniuToken
                  key:(NSString *)key
               option:(QNUploadOption *)option
      assetUseQuality:(BOOL)assetUseQuality
            complete:(void (^) (QNResponseInfo *info, NSString *key, NSDictionary *resp))completeBlock {
    
    if (!_uploadManager) {
        _uploadManager = [QNUploadManager sharedInstanceWithConfiguration:nil];
    }
    
    /******************NSData*********************/
    if ([obj isKindOfClass:[NSData class]]) {
        [_uploadManager putData:obj key:key token:qiniuToken complete:completeBlock option:option];
        return;
    }
    /******************NSData*********************/
    
    /******************UIImage*********************/
    if ([obj isKindOfClass:[UIImage class]]) {
        NSData *data = UIImageJPEGRepresentation(obj, 1.0);
        if (data.length > 1024*1024*_imageMinSize) {
            if (_imageQuality < 1.0) {
                data =  UIImageJPEGRepresentation(obj, _imageQuality);
            }
        }
        [_uploadManager putData:data key:key token:qiniuToken complete:completeBlock option:option];
        return;
    }
    /******************UIImage*********************/
    
    /******************PHAsset*********************/
    if ([obj isKindOfClass:[PHAsset class]]) {
        if (!assetUseQuality) {
            [_uploadManager putPHAsset:obj key:key token:qiniuToken complete:completeBlock option:option];
        }else{
            [self _uploadWithPHAsset:obj qiniuToken:qiniuToken key:key option:option complete:completeBlock];
        }
        
        return;
    }
    /******************PHAsset*********************/
    
    /******************ALAsset*********************/
    if ([obj isKindOfClass:[ALAsset class]]) {
        if (!assetUseQuality) {
            [_uploadManager putALAsset:obj key:key token:qiniuToken complete:completeBlock option:option];
        }else{
            [self _uploadWithALAsset:obj qiniuToken:qiniuToken key:key option:option complete:completeBlock];
        }
        return;
    }
    /******************ALAsset*********************/
    
    /******************MultiMediaObject*********************/
    if ([obj isKindOfClass:[MultiMediaObject class]]) {
        MultiMediaObject *mediaobj = obj;
        id asset = mediaobj.asset;
        if (asset) {
            
            if (mediaobj.mediaObjectType == MediaObjectTypeVideo||mediaobj.mediaObjectType == MediaObjectTypeVoice) {
                ///视频/语音
                if ([asset isKindOfClass:[PHAsset class]]) {
                    [_uploadManager putPHAsset:asset key:key token:qiniuToken complete:completeBlock option:option];
                    return;
                }else if([asset isKindOfClass:[ALAsset class]]){
                    [_uploadManager putALAsset:asset key:key token:qiniuToken complete:completeBlock option:option];
                    return;
                }
                
                NSAssert(NO,@"请检查数据音视频类型");
                
            }
            
            [self _uploadWithObj:asset qiniuToken:qiniuToken key:key option:option assetUseQuality:YES complete:completeBlock];
            return;
        }
        if (mediaobj.mediaObjectType == MediaObjectTypeUIImage) {
            UIImage *image = mediaobj.image;
            if (image) {
                [self _uploadWithObj:image qiniuToken:qiniuToken key:key option:option assetUseQuality:YES complete:completeBlock];
                return;
            }
        }
        if (mediaobj.netWorkObjUrl) {
            
            NSString *netWorkObjUrl = mediaobj.netWorkObjUrl;
            
            [self _uploadWithObj:netWorkObjUrl qiniuToken:qiniuToken key:key option:option assetUseQuality:assetUseQuality complete:completeBlock];
            return;
            //            option.progressHandler(key, 1.0);
            //            completeBlock(nil,key,@{@"key":mediaobj.netWorkObjUrl});
            return;
        }else{
            NSAssert(NO,@"请检查上传数据类型！！！");
        }
        
        
    }
    /******************MultiMediaObject*********************/
    
    /******************NSString*********************/
    if ([obj isKindOfClass:[NSString class]]) {
        if ([obj hasPrefix:@"file:"]||[obj hasPrefix:@"FILE:"]||[[NSFileManager defaultManager] fileExistsAtPath:obj]) {
            [_uploadManager putFile:obj key:key token:qiniuToken complete:completeBlock option:option];
            return;
        }
        if ([obj hasPrefix:@"http"]) {
            option.progressHandler(key, 1.0);
            completeBlock(nil,key,@{@"key":obj});
            return;
        }
        NSAssert(NO,@"请检查上传数据类型！！！");
    }
    /******************NSString*********************/
    
    /******************NSURL*********************/
    if ([obj isKindOfClass:[NSURL class]]) {
        
        if ([obj isFileURL]) {
            NSString *file = [obj path];
            [_uploadManager putFile:file key:key token:qiniuToken complete:completeBlock option:option];
            
            return;
        }
        if ([[obj absoluteString] hasPrefix:@"http"]) {
            option.progressHandler(key, 1.0);
            completeBlock(nil,key,@{@"key":obj});
            return;
        }
        NSAssert(NO, @"请检查上传数据类型！！！");
    }
    /******************NSURL*********************/
    
}


- (void)_uploadWithPHAsset:(PHAsset *)phasset
               qiniuToken:(NSString *)qiniuToken
                      key:(NSString *)key
                   option:(QNUploadOption *)option
                complete:(void (^) (QNResponseInfo *info, NSString *key, NSDictionary *resp))completeBlock {
    
    if (phasset.mediaType != PHAssetMediaTypeImage) {
        [_uploadManager putPHAsset:phasset key:key token:qiniuToken complete:completeBlock option:option];
        return;
    }
    
    
    __weak typeof(self) weakSelf = self;
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    
    [[PHImageManager defaultManager] requestImageDataForAsset:phasset options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
        
        NSData *putdata = nil;
        
        if ([dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
            ///GIF原图上传
            putdata = imageData;
        }else{
            UIImage *result = [UIImage imageWithData:imageData];
            if (!putdata) {
                putdata = UIImageJPEGRepresentation(result, 1.0);
                if (putdata.length > 1024*1024*weakSelf.imageMinSize) {
                    if (weakSelf.imageQuality < 1.0) {
                        putdata =  UIImageJPEGRepresentation(result, weakSelf.imageQuality);
                    }
                }
                //                putdata = UIImageJPEGRepresentation(result, weakSelf.Quality);
                if (!putdata.length) {
                    putdata = UIImagePNGRepresentation(result);
                }
            }
        }
        
        [weakSelf.uploadManager putData:putdata key:key token:qiniuToken complete:completeBlock option:option];
        
    }];
    
}

- (void)_uploadWithALAsset:(ALAsset *)alAsset
               qiniuToken:(NSString *)qiniuToken
                      key:(NSString *)key
                   option:(QNUploadOption *)option
                complete:(void (^) (QNResponseInfo *info, NSString *key, NSDictionary *resp))completeBlock {
    
    if (![[alAsset valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypePhoto]) {
        [_uploadManager putALAsset:alAsset key:key token:qiniuToken complete:completeBlock option:option];
        return;
    }
    
    CGImageRef imageref = [alAsset defaultRepresentation].fullScreenImage;
    
    UIImage *image = [UIImage imageWithCGImage:imageref];
    ALAssetRepresentation *re = [alAsset representationForUTI: (__bridge NSString *)kUTTypeGIF];
    
    if (re) {
        ///GIF原图上传
        [_uploadManager putALAsset:alAsset key:key token:qiniuToken complete:completeBlock option:option];
    } else {
        NSData *putdata = nil;
        if (!putdata) {
            putdata = UIImageJPEGRepresentation(image, 1.0);
            if (putdata.length > 1024*1024*self.imageMinSize) {
                if (self.imageQuality < 1.0) {
                    putdata =  UIImageJPEGRepresentation(image, self.imageQuality);
                }
            }
            //            putdata = UIImageJPEGRepresentation(image, _Quality);
            if (!putdata.length) {
                putdata = UIImagePNGRepresentation(image);
            }
        }
        
        [_uploadManager putData:putdata key:key token:qiniuToken complete:completeBlock option:option];
        
    }
    
}


@end
