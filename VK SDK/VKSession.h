//
//  VKSession.h
//  vk
//
//  Created by Ruslan Kavetsky on 2/7/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^VKSessionHandler)(NSError *error);

@class VKSession;

@interface VKSession : NSObject

@property (readonly) NSString *accessToken;
@property (readonly) NSString *userId;

+ (VKSession *)openSessionWithAppId:(NSString *)appId permissions:(NSString *)permissions handler:(VKSessionHandler)handler;
+ (VKSession *)activeSession;

- (void)close:(VKSessionHandler)handler;

@end
