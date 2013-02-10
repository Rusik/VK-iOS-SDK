//
//  VKClient.h
//  vk
//
//  Created by Ruslan Kavetsky on 2/8/13.
//  Copyright (c) 2013 Ruslan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKSession.h"

typedef void(^VKSuccessBlock)(NSDictionary *result);
typedef void(^VKFailureBlock)(NSError *error);

@class VKClient;

@interface VKClient : NSObject

- (id)initWithSession:(VKSession *)session;
- (void)sendRequestWithMethod:(NSString *)method parameters:(NSDictionary *)parameters success:(VKSuccessBlock)success failure:(VKFailureBlock)failure;

@end
