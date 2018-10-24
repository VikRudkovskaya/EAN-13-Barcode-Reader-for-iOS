//
//  AppDelegate.m
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 14.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

#import "AppDelegate.h"
#import "AnalyzeImageViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.mainWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    AnalyzeImageViewController *viewController = [[AnalyzeImageViewController alloc] initWithNibName:NSStringFromClass([AnalyzeImageViewController class]) bundle:nil];
    self.mainWindow.rootViewController = viewController;
    [self.mainWindow makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {

}

- (void)applicationDidEnterBackground:(UIApplication *)application {

}

- (void)applicationWillEnterForeground:(UIApplication *)application {

}

- (void)applicationDidBecomeActive:(UIApplication *)application {

}

- (void)applicationWillTerminate:(UIApplication *)application {

}

@end
