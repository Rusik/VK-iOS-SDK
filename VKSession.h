//
//  VKSession.h
//  vk
//
//  Created by Ruslan Kavetsky on 2/7/13.
//  Copyright (c) 2013 Ruslan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VKSession;

@protocol VSSessionDelegate <NSObject>

@optional
- (void)vkSessionDidLogin:(VKSession *)session;
- (void)vkSsionLoginDidFail:(VKSession *)session;

- (void)vkSessionTokenDidUpdate:(VKSession *)session;
- (void)vkSessionTokenUpdateDidFailed:(VKSession *)session;

- (void)vkSessionDidLogout:(VKSession *)session;

@end

@interface VKSession : NSObject

@property (readonly) NSString *accessToken;
@property (readonly) NSString *userId;

- (id)initWithAppId:(NSString *)appId permissions:(NSString *)permissions;

+ (VKSession *)sharedSession;
+ (void)setSharedSession:(VKSession *)session;

- (BOOL)isAuthorized;
- (void)loginFromViewController:(UIViewController *)viewController;
- (void)logout;
- (BOOL)isTokenValid;
- (void)updateToken;

@end
