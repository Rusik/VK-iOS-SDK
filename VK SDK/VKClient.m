//
//  VKClient.m
//  vk
//
//  Created by Ruslan Kavetsky on 2/8/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import "VKClient.h"
#import "NSString+VK.h"
#import "AFNetworking.h"

#define CAPTCHA_SID_KEY @"CaptchaSidKey"
#define CAPTCHA_IMAGE_KEY @"CaptchaImageKey"

#define REQUEST_KEY @"RequestKey"
#define SUCCESS_BLOCK_KEY @"SuccessBlockKey"
#define FAILURE_BLOCK_KEY @"FailureBlockKey"

#define ERROR_DOMAIN @"com.ruslankavetsky.VKSDK.VKClient"

#define LOG 0

typedef void(^SuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, id JSON);
typedef void(^FailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON);


@interface VKClient () <UIAlertViewDelegate>

@end

@implementation VKClient {
    NSDictionary *_captchaRequestInfo;
    NSDictionary *_captchaInfo;
    NSString *_captchaText;
}

#pragma mark - Public

- (void)sendRequestWithMethod:(NSString *)method parameters:(NSDictionary *)parameters handler:(VKResulthandler)handler {
    NSString *requestString = [self requestStringWithMethod:method];
    for (NSString *key in [parameters allKeys]) {
        requestString = [requestString stringByAppendingFormat:@"&%@=%@", key, [parameters objectForKey:key]];
    }
    
    requestString = [requestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    SuccessBlock successBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        NSDictionary *result = (NSDictionary *)JSON;
        if (handler) {
            handler(result, nil);
        }
    };
    FailureBlock failureBlock = ^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (handler) {
            handler(nil, error);
        }
    };
    [self sendRequest:requestString success:successBlock failure:failureBlock];
}

#pragma mark - Private

- (void)sendRequest:(NSString *)requestString success:(SuccessBlock)successBlock failure:(FailureBlock)failureBlock {
    
    if (![self isActiveSessionValid]) {
        return;
    }
    
    requestString = [requestString stringByAppendingFormat:@"&access_token=%@", [[VKSession activeSession] accessToken]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:requestString]];
    
    if (LOG) NSLog(@"Send request:\n%@", requestString);
    
    AFJSONRequestOperation *op =
    [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSDictionary *dict = (NSDictionary *)JSON;
        
        if (LOG) NSLog(@"Response recieved:\n%@", JSON);
        
        NSDictionary *captchaInfo = [self checkForCaptcha:dict];
        if (captchaInfo) {
            _captchaRequestInfo = @{REQUEST_KEY: request, SUCCESS_BLOCK_KEY: successBlock, FAILURE_BLOCK_KEY: failureBlock};
            _captchaInfo = captchaInfo;
            [self showAlertViewWithCaptcha];
            return;
        }
        
        NSError *error = [self checkForError:dict];
        if (error) {
            if (failureBlock) {
                failureBlock(request, response, error, JSON);
            }
            return;
        }
        
        if (successBlock) {
            successBlock(request, response, JSON);
        }
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        if (failureBlock) {
            failureBlock(request, response, error, JSON);
        }
    }];
    [op start];
}

- (NSDictionary *)checkForCaptcha:(NSDictionary *)response {
    if ([response objectForKey:@"error"]) {
        NSString *captchaSid = [[response objectForKey:@"error"] objectForKey:@"captcha_sid"];
        NSString *captchaImage = [[response objectForKey:@"error"] objectForKey:@"captcha_img"];
        if (captchaSid) {
            return @{CAPTCHA_SID_KEY: captchaSid, CAPTCHA_IMAGE_KEY: captchaImage};
        }
    }
    return nil;
}

- (NSError *)checkForError:(NSDictionary *)response {
    if ([response objectForKey:@"error"]) {
        NSString *errorMessage = [[response objectForKey:@"error"] objectForKey:@"error_msg"];
        NSString *errorCode = [[response objectForKey:@"error"] objectForKey:@"error_code"];
        NSError *error = [NSError errorWithDomain:ERROR_DOMAIN code:[errorCode intValue] userInfo:@{@"error_msg": errorMessage}];
        return error;
    }
    return nil;
}

- (BOOL)isActiveSessionValid {
    VKSession *activeSession = [VKSession activeSession];
    if (!activeSession.isAuthorized) {
        NSLog(@"ERROR: active session is not authorized");
        return NO;
    } else {
        if (!activeSession.isTokenValid) {
            NSLog(@"ERROR: access token is not valid");
            return NO;
        }
    }
    return YES;
}

#define TEXT_FIELD_TAG 99

- (void)showAlertViewWithCaptcha {
    CGSize alertViewSize = CGSizeMake(284, 206);
    CGSize captchaImageSize = CGSizeMake(130, 50);
    CGFloat captchaOriginY = 45;
    CGFloat separator = 10;
    CGFloat textFieldHeight = 30;
    
    NSString *captchaImage = [_captchaInfo objectForKey:CAPTCHA_IMAGE_KEY];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Введите код:\n\n\n\n", nil) message:@"\n" delegate:self cancelButtonTitle:NSLocalizedString(@"Отмена", nil) otherButtonTitles:NSLocalizedString(@"Готово", nil), nil];
    
    UIImageView *imageView = [[UIImageView alloc] init];
    CGRect frame;
    frame.size = captchaImageSize;
    frame.origin.x = floorf((alertViewSize.width - captchaImageSize.width) / 2);
    frame.origin.y = captchaOriginY;
    imageView.frame = frame;
    imageView.backgroundColor = [UIColor whiteColor];
    [imageView setImageWithURL:[NSURL URLWithString:captchaImage] placeholderImage:nil];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(imageView.frame.origin.x, CGRectGetMaxY(imageView.frame) + separator, imageView.frame.size.width, textFieldHeight)];
    [textField setBackgroundColor:[UIColor whiteColor]];
    
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.tag = TEXT_FIELD_TAG;
    textField.textAlignment = NSTextAlignmentCenter;
    textField.contentVerticalAlignment = UIControlContentHorizontalAlignmentCenter;
    
    [alertView addSubview:imageView];
    [alertView addSubview:textField];
    [alertView show];
    
    [textField becomeFirstResponder];
}

- (void)resendRequestWithCaptha {
    NSURLRequest *request = [_captchaRequestInfo objectForKey:REQUEST_KEY];
    NSString *requestString = request.URL.absoluteString;
    
    requestString = [requestString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"&access_token=%@", [requestString valueForParameter:@"access_token"]] withString:@""];
    requestString = [requestString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"&captcha_sid=%@", [requestString valueForParameter:@"captcha_sid"]] withString:@""];
    requestString = [requestString stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"&captcha_key=%@", [requestString valueForParameter:@"captcha_key"]] withString:@""];
    
    NSString *captchaSid = [_captchaInfo objectForKey:CAPTCHA_SID_KEY];
    requestString = [requestString stringByAppendingFormat:@"&captcha_sid=%@&captcha_key=%@", captchaSid, _captchaText];
    [self sendRequest:requestString success:[_captchaRequestInfo objectForKey:SUCCESS_BLOCK_KEY] failure:[_captchaRequestInfo objectForKey:FAILURE_BLOCK_KEY]];
    _captchaRequestInfo = nil;
    _captchaInfo = nil;
    _captchaText = nil;
}

- (NSString *)requestStringWithMethod:(NSString *)method {
    return [NSString stringWithFormat:@"https://api.vk.com/method/%@?", method];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        UITextView *textView = (UITextView *)[alertView viewWithTag:TEXT_FIELD_TAG];
        _captchaText = textView.text;
        [self resendRequestWithCaptha];
    }
}

@end
