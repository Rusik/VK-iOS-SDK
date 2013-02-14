//
//  VKConnectController.h
//  vk
//
//  Created by Ruslan Kavetsky on 2/7/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import <UIKit/UIKit.h>

@class VKConnectController;

@protocol VKConnectControllerDelegate <NSObject>
@optional
- (void)vkController:(VKConnectController *)controller didLoginWithAccessToken:(NSString *)token expirationDate:(NSDate *)date userId:(NSString *)userId;
- (void)vkControllerLoginDidFail:(VKConnectController *)controller withError:(NSError *)error;
@end

@interface VKConnectController : UIViewController

@property (nonatomic, assign) id<VKConnectControllerDelegate> delegate;

- (id)initWithUrl:(NSString *)url;

@end
