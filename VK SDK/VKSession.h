//
//  VKSession.h
//  vk
//
//  Created by Ruslan Kavetsky on 2/7/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VKSession;

@protocol VKSessionDelegate <NSObject>

@optional
- (void)vkSessionDidLogin:(VKSession *)session;
- (void)vkSessionLoginDidFail:(VKSession *)session withError:(NSError *)error;

- (void)vkSessionTokenDidUpdate:(VKSession *)session;
- (void)vkSessionTokenUpdateDidFailed:(VKSession *)session withError:(NSError *)error;

- (void)vkSessionDidLogout:(VKSession *)session;
- (void)vkSessionLogoutDidFail:(VKSession *)session withError:(NSError *)error;

@end

@interface VKSession : NSObject

@property (readonly) NSString *accessToken;
@property (readonly) NSString *userId;

@property (weak) id<VKSessionDelegate> delegate;

+ (VKSession *)openSessionWithAppId:(NSString *)appId permissions:(NSString *)permissions;
+ (VKSession *)activeSession;

- (void)login;
- (void)logout;
- (void)updateToken;

- (BOOL)isAuthorized;
- (BOOL)isTokenValid;

@end
