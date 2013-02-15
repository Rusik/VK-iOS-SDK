//
//  VKSession.m
//  vk
//
//  Created by Ruslan Kavetsky on 2/7/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import "VKSession.h"
#import "VKConnectController.h"
#import "AFNetworking.h"
#import "NSString+VK.h"
#import "VKSession.h"

#define ACCESS_TOKEN_KEY @"VKAccessTokenKey"
#define USER_ID_KEY @"VKuserIdKey"
#define EXPIRATION_DATE_KEY @"VkExpirationDateKey"

#define ERROR_DOMAIN @"com.ruslankavetsky.VKSDK.VKSession"

static VKSession *_activeSession = nil;

@implementation UIWindow (topMostController)

- (UIViewController *)topmostViewController {
    UIViewController *topmostViewController = [self rootViewController];
    while (topmostViewController.presentedViewController) {
        topmostViewController = topmostViewController.presentedViewController;
    }
    return topmostViewController;
}

@end

@interface VKSession () <VKConnectControllerDelegate>

@end

@implementation VKSession {
    NSString *_accsessToken;
    NSString *_userId;
    NSDate *_expirationDate;
    
    NSString *_appId;
    NSString *_permissions;
    
    VKSessionHandler _openHandler;
}

#pragma mark -

+ (VKSession *)openSessionWithAppId:(NSString *)appId permissions:(NSString *)permissions handler:(VKSessionHandler)handler {
    _activeSession = [[VKSession alloc] initWithAppId:appId permissions:permissions];
    if ([_activeSession isAuthorized]) {
        if ([_activeSession isTokenExpired]) {
            [_activeSession updateTokenOrOpenLoginScreen:handler];
        } else {
            if (handler) {
                handler(nil);
            }
        }
    } else {
        [_activeSession openLoginScreen:handler];
    }
    return _activeSession;
}

+ (VKSession *)activeSession {
    return _activeSession;
}

- (id)initWithAppId:(NSString *)appId permissions:(NSString *)permissions {
    self = [super init];
    if (self) {
        _appId = appId;
        _permissions = permissions;
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        _accsessToken = [userDefaults stringForKey:ACCESS_TOKEN_KEY];
        _userId = [userDefaults stringForKey:USER_ID_KEY];
        _expirationDate = [userDefaults objectForKey:EXPIRATION_DATE_KEY];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Access token: %@, User id: %@, Expiration date: %@", _accsessToken, _userId, _expirationDate];
}

#pragma mark - 

- (void)openLoginScreen:(VKSessionHandler)handler {
    VKConnectController *connectVC = [[VKConnectController alloc] initWithUrl:[self authString]];
    connectVC.delegate = self;
    _openHandler = handler;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:connectVC];
    UIViewController *topMostViewController = [[[UIApplication sharedApplication] keyWindow] topmostViewController];
    [topMostViewController presentViewController:navController animated:YES completion:nil];
}

- (void)updateTokenOrOpenLoginScreen:(VKSessionHandler)handler {
    __block NSURLRequest *redirectRequest = nil;
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[self authString]]]];
    
    [op setRedirectResponseBlock:^NSURLRequest *(NSURLConnection *connection, NSURLRequest *request, NSURLResponse *redirectResponse) {
        
        NSString *redirectUrl = request.URL.absoluteString;
        if ([redirectUrl rangeOfString:@"access_token"].location != NSNotFound) {
            _accsessToken = [redirectUrl valueForParameter:@"access_token"];
            _expirationDate = [NSDate dateWithTimeIntervalSinceNow:[[redirectUrl valueForParameter:@"expires_in"] intValue]];
            _userId = [redirectUrl valueForParameter:@"user_id"];
            redirectRequest = request;
            [self sync];
        }
        return request;
        
    }];
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        if (handler) {
            if (redirectRequest) {
                handler(nil);
            } else {
                [self openLoginScreen:handler];
            }
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        [self clearAll];
        
        if (handler) {
            handler(error);
        }
        
    }];
    
    [op start];
}

- (void)close:(VKSessionHandler)handler {
    NSString *logout = [NSString stringWithFormat:@"http://api.vk.com/oauth/logout?client_id=%@", _appId];
    
    NSURL *url = [NSURL URLWithString:logout];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        [self clearCookie];
        [self clearAll];
        
        if (handler) {
            handler(nil);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {

        if (handler) {
            handler(error);
        }
        
    }];
    
    [op start];
}

- (void)reopenSession:(VKSessionHandler)handler {
    [_activeSession updateTokenOrOpenLoginScreen:handler];
}

- (BOOL)isTokenExpired {
    NSDate *currentDate = [NSDate date];
    return !([currentDate compare:_expirationDate] == NSOrderedAscending);
}

- (BOOL)isAuthorized {
    return _expirationDate && _accsessToken && _userId;
}

- (void)clearAll {
    _accsessToken = nil;
    _expirationDate = nil;
    _userId = nil;
    _activeSession = nil;
    [self sync];
}

#pragma mark - Properties

- (NSString *)accessToken {
    return _accsessToken;
}

- (NSString *)userId {
    return _userId;
}

#pragma mark - Private

- (NSString *)authString {
    return [NSString stringWithFormat:@"https://oauth.vk.com/authorize?client_id=%@&scope=%@&redirect_uri=http://oauth.vk.com/blank.html&display=touch&response_type=token", _appId, _permissions];
}

- (void)sync {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:_accsessToken forKey:ACCESS_TOKEN_KEY];
    [userDefaults setObject:_userId forKey:USER_ID_KEY];
    [userDefaults setObject:_expirationDate forKey:EXPIRATION_DATE_KEY];
    [userDefaults synchronize];
}

- (void)clearCookie {
    NSHTTPCookieStorage *cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *vkCookies1 = [cookies cookiesForURL:[NSURL URLWithString:@"http://api.vk.com"]];
    NSArray *vkCookies2 = [cookies cookiesForURL:[NSURL URLWithString:@"http://vk.com"]];
    NSArray *vkCookies3 = [cookies cookiesForURL:[NSURL URLWithString:@"http://login.vk.com"]];
    NSArray *vkCookies4 = [cookies cookiesForURL:[NSURL URLWithString:@"http://oauth.vk.com"]];
    NSArray *vkCookies5 = [cookies cookiesForURL:[NSURL URLWithString:@"https://api.vk.com"]];
    NSArray *vkCookies6 = [cookies cookiesForURL:[NSURL URLWithString:@"https://vk.com"]];
    NSArray *vkCookies7 = [cookies cookiesForURL:[NSURL URLWithString:@"https://login.vk.com"]];
    NSArray *vkCookies8 = [cookies cookiesForURL:[NSURL URLWithString:@"https://oauth.vk.com"]];
    
    for (NSHTTPCookie *cookie in vkCookies1) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies2) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies3) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies4) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies5) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies6) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies7) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie *cookie in vkCookies8) {
        [cookies deleteCookie:cookie];
    }
}

#pragma mark - VKConnectControllerDelegate

- (void)vkController:(VKConnectController *)controller didLoginWithAccessToken:(NSString *)token expirationDate:(NSDate *)date userId:(NSString *)userId {
    _accsessToken = token;
    _expirationDate = date;
    _userId = userId;
    [self sync];
    if (_openHandler) {
        _openHandler(nil);
        _openHandler = nil;
    }
}

- (void)vkControllerLoginDidFail:(VKConnectController *)controller withError:(NSError *)error {
    [self clearAll];
    if (_openHandler) {
        _openHandler(error);
        _openHandler = nil;
    }
}

@end
