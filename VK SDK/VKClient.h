//
//  VKClient.h
//  vk
//
//  Created by Ruslan Kavetsky on 2/8/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VKSession.h"

typedef void(^VKClientHandler)(NSDictionary *result, NSError *error);

@class VKClient;

@interface VKClient : NSObject

- (void)sendRequestWithMethod:(NSString *)method parameters:(NSDictionary *)parameters handler:(VKClientHandler)handler;

@end
