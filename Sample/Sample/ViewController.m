//
//  ViewController.m
//  Sample
//
//  Created by Ruslan Kavetsky on 2/14/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import "ViewController.h"
#import "VKSDK.h"
#import "AFNetworking.h"

#define APP_ID @"your_app_id"
#define PERMISSIONS @"needed_permissions"

@implementation ViewController {
    IBOutlet UIImageView *avatar;
    IBOutlet UILabel *name;
    IBOutlet UIButton *loginButton;
    
    VKSession *_vkSession;
    VKClient *_vkClient;
}

- (VKClient *)vkClient {
    if (!_vkClient) {
        _vkClient = [[VKClient alloc] init];
    }
    return _vkClient;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
}

- (void)openSession {
    [VKSession openSessionWithAppId:APP_ID permissions:PERMISSIONS handler:^(NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            [loginButton setTitle:@"Login" forState:UIControlStateNormal];
            [loginButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        } else {
            [self profile];
            [loginButton setTitle:@"Logout" forState:UIControlStateNormal];
            [loginButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [loginButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
        }
        NSLog(@"%@", [VKSession activeSession]);
    }];    
}

#pragma mark - Private

- (void)profile {
    [[self vkClient] sendRequestWithMethod:@"users.get" parameters:@{@"fields": @"photo_big"} handler:^(NSDictionary *result, NSError *error) {
        if (error) {
            NSLog(@"%@", error);
            return;
        }
        NSDictionary *user = [[result objectForKey:@"response"] lastObject];
        NSString *firtsName = [user objectForKey:@"first_name"];
        NSString *lastName = [user objectForKey:@"last_name"];
        NSString *imageUrlString = [user objectForKey:@"photo_big"];
        
        name.text = [firtsName stringByAppendingFormat:@" %@", lastName];
        [avatar setImageWithURL:[NSURL URLWithString:imageUrlString]];
    }];
}

- (void)login {
    [self openSession];
}

- (void)logout {
    [[VKSession activeSession] close:^(NSError *error) {
        [loginButton setTitle:@"Login" forState:UIControlStateNormal];
        [loginButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
        [avatar setImage:nil];
        name.text = @"";        
    }];
}

@end
