//
//  MKNGoogleLoginViewController.h
//  MeekanSDK
//
//  Created by Eyal Yavor on 30/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MKNParameters.h"
#import "MKNApiAdapter.h"

@class MKNGoogleLoginViewController;

extern NSString *const kMKNGoogleLoginUrl;


typedef void (^MKNGoogleLoginViewControllerCompletionHandler)(MKNGoogleLoginViewController *viewController, ConnectedUser *auth, NSError *error);

@interface MKNGoogleLoginViewController : UIViewController <UIWebViewDelegate>
@property (nonatomic, strong) id<ApiAdapter> adapter;
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@property (nonatomic, strong) MKNGoogleLoginViewControllerCompletionHandler completion;
@end
