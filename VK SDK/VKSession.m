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

#define ACCESS_TOKEN_KEY @"VKAccessTokenKey"
#define USER_ID_KEY @"VKuserIdKey"
#define EXPIRATION_DATE_KEY @"VkExpirationDateKey"

#define ERROR_DOMAIN @"com.ruslankavetsky.VKSDK.VKSession"

static VKSession *_sharedSession = nil;

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
}

#pragma mark -

+ (VKSession *)sharedSession {
    return _sharedSession;
}

+ (void)setSharedSession:(VKSession *)session {
    _sharedSession = session;
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

#pragma mark - Public

- (BOOL)isAuthorized {
    return _expirationDate != nil && _accsessToken != nil && _userId != nil;
}

- (void)login {
    VKConnectController *connectVC = [[VKConnectController alloc] initWithUrl:[self authString]];
    connectVC.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:connectVC];
    UIViewController *topMostViewController = [[[UIApplication sharedApplication] keyWindow] topmostViewController];
    [topMostViewController presentViewController:navController animated:YES completion:nil];
}

- (void)logout {
    NSString *logout = [NSString stringWithFormat:@"http://api.vk.com/oauth/logout?client_id=%@", _appId];
    
    NSURL *url = [NSURL URLWithString:logout];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self clearCookie];
        _accsessToken = nil;
        _expirationDate = nil;
        _userId = nil;
        [self sync];
        if ([self.delegate respondsToSelector:@selector(vkSessionDidLogout:)]) {
            [self.delegate vkSessionDidLogout:self];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(vkSessionLoginDidFail:withError:)]) {
            [self.delegate vkSessionLogoutDidFail:self withError:error];
        }
    }];
    [op start];
}

- (BOOL)isTokenValid {
    return [[NSDate date] earlierDate:_expirationDate] && _accsessToken != nil && _userId != nil;
}

- (void)updateToken {
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
        if (redirectRequest) {
            if ([self.delegate respondsToSelector:@selector(vkSessionTokenDidUpdate:)]) {
                [self.delegate vkSessionTokenDidUpdate:self];
            }
        } else {
            if ([self.delegate respondsToSelector:@selector(vkSessionTokenUpdateDidFailed:withError:)]) {
                [self.delegate vkSessionTokenUpdateDidFailed:self withError:[NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:@{@"unknown error": @"can't update token"}]];
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(vkSessionTokenUpdateDidFailed:withError:)]) {
            [self.delegate vkSessionTokenUpdateDidFailed:self withError:error];
        }
             
    }];
    [op start];
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
    NSHTTPCookieStorage* cookies = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *vkCookies1 = [cookies cookiesForURL:[NSURL URLWithString:@"http://api.vk.com"]];
    NSArray *vkCookies2 = [cookies cookiesForURL:[NSURL URLWithString:@"http://vk.com"]];
    NSArray *vkCookies3 = [cookies cookiesForURL:[NSURL URLWithString:@"http://login.vk.com"]];
    NSArray *vkCookies4 = [cookies cookiesForURL:[NSURL URLWithString:@"http://oauth.vk.com"]];
    NSArray *vkCookies5 = [cookies cookiesForURL:[NSURL URLWithString:@"https://api.vk.com"]];
    NSArray *vkCookies6 = [cookies cookiesForURL:[NSURL URLWithString:@"https://vk.com"]];
    NSArray *vkCookies7 = [cookies cookiesForURL:[NSURL URLWithString:@"https://login.vk.com"]];
    NSArray *vkCookies8 = [cookies cookiesForURL:[NSURL URLWithString:@"https://oauth.vk.com"]];
    
    for (NSHTTPCookie* cookie in vkCookies1) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie* cookie in vkCookies2) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie* cookie in vkCookies3) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie* cookie in vkCookies4) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie* cookie in vkCookies5) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie* cookie in vkCookies6) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie* cookie in vkCookies7) {
        [cookies deleteCookie:cookie];
    }
    for (NSHTTPCookie* cookie in vkCookies8) {
        [cookies deleteCookie:cookie];
    }
}

#pragma mark - VKConnectControllerDelegate

- (void)vkController:(VKConnectController *)controller didLoginWithAccessToken:(NSString *)token expirationDate:(NSDate *)date userId:(NSString *)userId {
    _accsessToken = token;
    _expirationDate = date;
    _userId = userId;
    [self sync];
    if ([self.delegate respondsToSelector:@selector(vkSessionDidLogin:)]) {
        [self.delegate vkSessionDidLogin:self];
    }
}

- (void)vkControllerLoginDidFail:(VKConnectController *)controller withError:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(vkSessionLoginDidFail:withError:)]) {
        [self.delegate vkSessionLoginDidFail:self withError:error];
    }
}

@end
