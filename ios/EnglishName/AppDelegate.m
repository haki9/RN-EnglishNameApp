/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "AppDelegate.h"
#import "CodePush.h"

#import "RCTBundleURLProvider.h"
#import "RCTRootView.h"

#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@import UserNotifications;
#endif

@import Firebase;
@import FirebaseInstanceID;
@import FirebaseMessaging;


// Implement UNUserNotificationCenterDelegate to receive display notification via APNS for devices
// running iOS 10 and above. Implement FIRMessagingDelegate to receive data message via FCM for
// devices running iOS 10 and above.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
@interface AppDelegate () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>
@end
#endif

// Copied from Apple's header in case it is missing in some cases (e.g. pre-Xcode 8 builds).
#ifndef NSFoundationVersionNumber_iOS_9_x_Max
#define NSFoundationVersionNumber_iOS_9_x_Max 1299
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  NSURL *jsCodeLocation;

  
#ifdef DEBUG
    jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios" fallbackResource:nil];
#else
    jsCodeLocation = [CodePush bundleURL];
#endif

  RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                      moduleName:@"EnglishName"
                                               initialProperties:nil
                                                   launchOptions:launchOptions];
  rootView.backgroundColor = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1];

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  UIViewController *rootViewController = [UIViewController new];
  rootViewController.view = rootView;
  self.window.rootViewController = rootViewController;
  [self.window makeKeyAndVisible];
  
  // Register for remote notifications
  if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
    // iOS 7.1 or earlier. Disable the deprecation warnings.
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    UIRemoteNotificationType allNotificationTypes =
    (UIRemoteNotificationTypeSound |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeBadge);
    [application registerForRemoteNotificationTypes:allNotificationTypes];
#pragma clang diagnostic pop
  } else {
    // iOS 8 or later
    // [START register_for_notifications]
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
      UIUserNotificationType allNotificationTypes =
      (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
      UIUserNotificationSettings *settings =
      [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
      [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
      // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
      UNAuthorizationOptions authOptions =
      UNAuthorizationOptionAlert
      | UNAuthorizationOptionSound
      | UNAuthorizationOptionBadge;
      [[UNUserNotificationCenter currentNotificationCenter]
       requestAuthorizationWithOptions:authOptions
       completionHandler:^(BOOL granted, NSError * _Nullable error) {
       }
       ];
      
      // For iOS 10 display notification (sent via APNS)
      [[UNUserNotificationCenter currentNotificationCenter] setDelegate:self];
      // For iOS 10 data message (sent via FCM)
      [[FIRMessaging messaging] setRemoteMessageDelegate:self];
#endif
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    // [END register_for_notifications]
  }
  
  // [START configure_firebase]
  [FIRApp configure];
  // [END configure_firebase]
  // Add observer for InstanceID token refresh callback.
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:)
                                               name:kFIRInstanceIDTokenRefreshNotification object:nil];  return YES;
  
}

// [START receive_message]
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
  // If you are receiving a notification message while your app is in the background,
  // this callback will not be fired till the user taps on the notification launching the application.
  // TODO: Handle data of notification
  
  // Print message ID.
  NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);
  
  // Print full message.
  NSLog(@"%@", userInfo);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
  // If you are receiving a notification message while your app is in the background,
  // this callback will not be fired till the user taps on the notification launching the application.
  // TODO: Handle data of notification
  
  // Print message ID.
  NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);
  
  // Print full message.
  NSLog(@"%@", userInfo);
}
// [END receive_message]

// [START ios_10_message_handling]
// Receive displayed notifications for iOS 10 devices.
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
  // Print message ID.
  NSDictionary *userInfo = notification.request.content.userInfo;
  NSLog(@"Message ID: %@", userInfo[@"gcm.message_id"]);
  
  // Print full message.
  NSLog(@"%@", userInfo);
}

// Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center
didReceiveNotificationResponse:(UNNotificationResponse *)response
         withCompletionHandler:(void (^)())completionHandler {
  NSDictionary *userInfo = response.notification.request.content.userInfo;
  NSLog(@"%@", userInfo);
}
#endif
// [END ios_10_message_handling]

// [START ios_10_data_message_handling]
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
// Receive data message on iOS 10 devices while app is in the foreground.
- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage {
  // Print full message
  NSLog(@"%@", [remoteMessage appData]);
}
#endif
// [END ios_10_data_message_handling]

// [START refresh_token]
- (void)tokenRefreshNotification:(NSNotification *)notification {
  // Note that this callback will be fired everytime a new token is generated, including the first
  // time. So if you need to retrieve the token as soon as it is available this is where that
  // should be done.
  NSString *refreshedToken = [[FIRInstanceID instanceID] token];
  NSLog(@"InstanceID token: %@", refreshedToken);
  
  // Connect to FCM since connection may have failed when attempted before having a token.
  [self connectToFcm];
  
  // TODO: If necessary send token to application server.
}
// [END refresh_token]

// [START connect_to_fcm]
- (void)connectToFcm {
  [[FIRMessaging messaging] connectWithCompletion:^(NSError * _Nullable error) {
    if (error != nil) {
      NSLog(@"Unable to connect to FCM. %@", error);
    } else {
      NSLog(@"Connected to FCM.");
    }
  }];
}
// [END connect_to_fcm]

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
  NSLog(@"Unable to register for remote notifications: %@", error);
}

// This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
// If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
// the InstanceID token.
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
  NSLog(@"APNs token retrieved: %@", deviceToken);
  
  // With swizzling disabled you must set the APNs token here.
  // [[FIRInstanceID instanceID] setAPNSToken:deviceToken type:FIRInstanceIDAPNSTokenTypeSandbox];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  [self connectToFcm];
}

// [START disconnect_from_fcm]
- (void)applicationDidEnterBackground:(UIApplication *)application {
  [[FIRMessaging messaging] disconnect];
  NSLog(@"Disconnected from FCM");
}
// [END disconnect_from_fcm]


@end
