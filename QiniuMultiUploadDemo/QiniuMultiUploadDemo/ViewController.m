//
//  ViewController.m
//  QiniuMultiUploadDemo
//
//  Created by namewzz on 2019/10/12.
//  Copyright © 2019 namewzz. All rights reserved.
//

#import "ViewController.h"
#import <MBProgressHUD.h>
#import "QiniuMultiUploadManager.h"

#import <pthread.h>

#define uploadToken  @""//你的七牛上传token

@interface ViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@end

static inline void dispatch_async_on_main_queue(void (^block)(void)) {
    if (pthread_main_np()) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *button = [UIButton buttonWithType:0];
    button.frame = CGRectMake(0, 0, 160, 50);
    button.center = self.view.center;
    button.backgroundColor = UIColor.lightGrayColor;
    [button setTitle:@"选择图片上传" forState:0];
    [self.view addSubview:button];
    [button addTarget:self action:@selector(ChooseClick) forControlEvents:UIControlEventTouchUpInside];
}

- (void)ChooseClick {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc]init];
    imagePickerController.delegate = self;
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:imagePickerController animated:YES completion:NULL];
}

- (void)uploadOne {
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.detailsLabel.text = @"正在上传";
    NSArray *files = @[[@"123" dataUsingEncoding:NSUTF8StringEncoding]];
    [[QiniuMultiUploadManager sharedManager] uploadFiles:files qiniuToken:uploadToken progress:^(double progress) {
        NSLog(@"progress = %f",progress);
        HUD.label.text = [NSString stringWithFormat:@"%0.f%@",progress*99,@"%"];
    } sucess:^(NSDictionary * _Nonnull resp, NSArray * _Nonnull sortValueArray) {
        NSLog(@"resp = %@ 排序过的value = %@", resp, sortValueArray);
        dispatch_async_on_main_queue( ^{
            [HUD hideAnimated:YES];
        });
    } failure:^(NSError * _Nonnull error, NSArray * _Nonnull failureArray) {
        NSLog(@"失败的file = %@", failureArray);
        dispatch_async_on_main_queue( ^{
            HUD.label.text = [NSString stringWithFormat:@"失败%lu个",(unsigned long)failureArray.count];
            [HUD hideAnimated:YES afterDelay:1.0];
        });
    }];
}

- (void)uploadMoreWithImage:(UIImage *)image{
    MBProgressHUD *HUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    HUD.detailsLabel.text = @"正在上传";
    
    NSArray *files = @[image,[@"123" dataUsingEncoding:NSUTF8StringEncoding],[UIImage imageNamed:@"1.png"]];
    [[QiniuMultiUploadManager sharedManager] uploadFiles:files qiniuToken:uploadToken progress:^(double progress) {
        NSLog(@"progress = %f",progress);
        HUD.label.text = [NSString stringWithFormat:@"%0.f%@",progress*99,@"%"];
    } sucess:^(NSDictionary * _Nonnull resp, NSArray * _Nonnull sortValueArray) {
        NSLog(@"resp = %@ 排序过的value = %@", resp, sortValueArray);
        dispatch_async_on_main_queue( ^{
            [HUD hideAnimated:YES];
        });
    } failure:^(NSError * _Nonnull error, NSArray * _Nonnull failureArray) {
        NSLog(@"失败的file = %@", failureArray);
        dispatch_async_on_main_queue( ^{
            HUD.label.text = [NSString stringWithFormat:@"失败%lu个",(unsigned long)failureArray.count];
            [HUD hideAnimated:YES afterDelay:1.0];
        });
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    [self dismissViewControllerAnimated:YES completion:NULL];
    if (image) {
        [self uploadMoreWithImage:image];
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
