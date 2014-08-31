//
//  MKNGoogleLoginViewController.m
//  MeekanSDK
//
//  Created by Eyal Yavor on 30/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import "MKNGoogleLoginViewController.h"

NSString *const kMKNBaseURL = @"http://localhost:8080";

static NSString *GOOGLE_SOCIAL_LOGIN = @"/social_login/google_oauth2";
static NSString *GOOGLE_SOCIAL_LOGIN_SUCCESS = @"/rest/auth";

@interface MKNGoogleLoginViewController ()
@property (nonatomic) BOOL wasShown;
@property (nonatomic) BOOL shouldPop;
@property (nonatomic) BOOL isRedirectedToFinal;
@end

@implementation MKNGoogleLoginViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[kMKNBaseURL stringByAppendingString:GOOGLE_SOCIAL_LOGIN]]];
    [self.webView loadRequest:request];
}

-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if ([request.URL.path isEqual:GOOGLE_SOCIAL_LOGIN_SUCCESS]) {
        self.isRedirectedToFinal = YES;
    }
    return YES;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.wasShown = YES;
    if (self.shouldPop) {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (self.completion) {
        self.completion(self, nil, error);
        [self popWhenPossible];
    }
}

-(void)webViewDidFinishLoad:(UIWebView *)webView {
    if (self.isRedirectedToFinal) {
        NSString *jsonString = [webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
        NSError *error;
        
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[jsonString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
        if (error) {
            self.completion(self, nil, error);
        } else {
            error = [self.adapter checkIfError:json];
            if (!error) {
                ConnectedUser *user = [self.adapter parseCurrentUserDetails:json andError:&error];
                if (user) {
                    self.completion(self, user, nil);
                } else {
                    self.completion(self, nil, error);
                }
            }
        }
        self.isRedirectedToFinal = NO;
        [self popWhenPossible];
    }
}

-(void)popWhenPossible {
    if (self.wasShown) {
        [self.navigationController popViewControllerAnimated:self.wasShown];
    } else {
        self.shouldPop = YES;
    }
}

@end
