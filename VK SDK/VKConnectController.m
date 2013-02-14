//
//  VKConnectController.m
//  vk
//
//  Created by Ruslan Kavetsky on 2/7/13.
//  Copyright (c) 2013 Ruslan Kavetsky. All rights reserved.
//

#import "VKConnectController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSString+VK.h"

#define ERROR_DOMAIN @"com.ruslankavetsky.VKSDK.VKConnectController"

@interface VKConnectController () <UIWebViewDelegate>

@end

@implementation VKConnectController {
    UIWebView *_webView;
    UIActivityIndicatorView *_spinner;
    NSString *_url;
}

- (id)initWithUrl:(NSString *)url {
    self = [super init];
    if (self) {
        _url = [url copy];
        
        self.title = NSLocalizedString(@"Вконтакте", nil);
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self createSubviews];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self loadRequest];
}

- (void)createSubviews {
    _webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.delegate = self;
    _webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _webView.scalesPageToFit = YES;
    _webView.dataDetectorTypes = UIDataDetectorTypeNone;
    [self.view addSubview:_webView];
    
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    _spinner.autoresizingMask =
    UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    CGRect frame = _spinner.frame;
    frame.origin.x = floorf(self.view.bounds.size.width / 2 - frame.size.width / 2);
    frame.origin.y = floorf(self.view.bounds.size.height / 2 - frame.size.height / 2) - 20;
    _spinner.frame = frame;
    [_spinner startAnimating];
    [self.view addSubview:_spinner];
}

- (void)loadRequest {
    NSURLRequest *urlRequest =
    [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:_url] cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:20];
    [_webView loadRequest:urlRequest];
}

- (void)cancel {
    if ([self.delegate respondsToSelector:@selector(vkControllerLoginDidFail:withError:)]) {
        [self.delegate vkControllerLoginDidFail:self withError:[NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:@{@"error_description" : @"user tap cancel button"}]];
    }    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    [_spinner stopAnimating];
    
    CATransition* transition = [CATransition animation];
    transition.duration = 0.25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    transition.type = kCATransitionFade;
    [self.view.layer addAnimation:transition forKey:nil];
    
    NSString *response = webView.request.URL.absoluteString;
    
    if ([response rangeOfString:@"access_token"].location != NSNotFound) {
        NSString *token = [response valueForParameter:@"access_token"];
        NSString *expires = [response valueForParameter:@"expires_in"];
        NSString *userId = [response valueForParameter:@"user_id"];
        
        NSDate *date = [NSDate dateWithTimeIntervalSinceNow:expires.intValue];
        
        if ([self.delegate respondsToSelector:@selector(vkController:didLoginWithAccessToken:expirationDate:userId:)]) {
            [self.delegate vkController:self didLoginWithAccessToken:token expirationDate:date userId:userId];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    
    if ([response rangeOfString:@"error"].location != NSNotFound) {
        
        NSString *error = [response valueForParameter:@"error"];
        NSString *errorReason = [response valueForParameter:@"error_reason"];
        NSString *errorDescription = [response valueForParameter:@"error_description"];
        
        if ([self.delegate respondsToSelector:@selector(vkControllerLoginDidFail:withError:)]) {
            [self.delegate vkControllerLoginDidFail:self withError:[NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:@{@"error" : error, @"error reason": errorReason, @"error description" : errorDescription}]];
        }
        [self dismissViewControllerAnimated:YES completion:nil];        
        return;
    }
    
    NSString *html = [webView stringByEvaluatingJavaScriptFromString: @"document.body.innerHTML"];
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:@"\\{.*\\}" options:0 error:nil];
    NSRange range = [regexp rangeOfFirstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
    NSString *jsonString;
    NSDictionary *jsonDict;
    if (range.location != NSNotFound) {
        jsonString = [html substringWithRange:range];
        jsonDict = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    }
    
    if ([jsonDict objectForKey:@"error"]) {
        NSString *error = [jsonDict objectForKey:@"error"];
        NSString *errorDescription = [jsonDict objectForKey:@"error_description"];
        
        if ([self.delegate respondsToSelector:@selector(vkControllerLoginDidFail:withError:)]) {
            [self.delegate vkControllerLoginDidFail:self withError:[NSError errorWithDomain:ERROR_DOMAIN code:0 userInfo:@{@"error" : error, @"error description" : errorDescription}]];
        }
        [self dismissViewControllerAnimated:YES completion:nil];        
        return;
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(vkControllerLoginDidFail:withError:)]) {
        [self.delegate vkControllerLoginDidFail:self withError:error];
    }
}

#pragma mark - Private



@end
