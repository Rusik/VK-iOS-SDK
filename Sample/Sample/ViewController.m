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

@interface ViewController () <VKSessionDelegate>

@end

@implementation ViewController {
    IBOutlet UIImageView *avatar;
    IBOutlet UILabel *name;
    IBOutlet UIButton *loginButton;
    
    VKSession *_vkSession;
    VKClient *_vkClient;
}

- (VKClient *)vkClient {
    if (!_vkClient) {
        _vkClient = [[VKClient alloc] initWithSession:[self vkSession]];
    }
    return _vkClient;
}

- (VKSession *)vkSession {
    if (!_vkSession) {
        _vkSession = [[VKSession alloc] initWithAppId:APP_ID permissions:PERMISSIONS];
        _vkSession.delegate = self;
    }
    return _vkSession;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([[self vkSession] isAuthorized]) {
        
        [loginButton setTitle:@"Logout" forState:UIControlStateNormal];
        [loginButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [loginButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
        
        if ([[self vkSession] isTokenValid]) {
            [self profile];
        } else {
            [[self vkSession] updateToken];
        }
    } else {
        [loginButton setTitle:@"Login" forState:UIControlStateNormal];
        [loginButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];        
        [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    }
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
    [[self vkSession] login];
}

- (void)logout {
    [[self vkSession] logout];
}

#pragma VKSessionDelegate

- (void)vkSessionDidLogin:(VKSession *)session {
    [loginButton setTitle:@"Logout" forState:UIControlStateNormal];
    [loginButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [loginButton addTarget:self action:@selector(logout) forControlEvents:UIControlEventTouchUpInside];
    [self profile];    
}

- (void)vkSessionLoginDidFail:(VKSession *)session withError:(NSError *)error{
    NSLog(@"%@", error);
}

- (void)vkSessionTokenDidUpdate:(VKSession *)session {
    [self profile];
}

- (void)vkSessionTokenUpdateDidFailed:(VKSession *)session withError:(NSError *)error{
    NSLog(@"%@", error);
}

- (void)vkSessionDidLogout:(VKSession *)session {
    [loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [loginButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];    
    [loginButton addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
    [avatar setImage:nil];
    name.text = @"";
}

- (void)vkSessionLogoutDidFail:(VKSession *)session withError:(NSError *)error{
    NSLog(@"%@", error);
}


@end
