//
//  AppDelegate.h
//  QiniuMultiUploadDemo
//
//  Created by namewzz on 2019/10/12.
//  Copyright © 2019 namewzz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;


@end

