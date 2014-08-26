//
//  MeekanSDK.h
//  MeekanSDK
//
//  Created by Eyal Yavor on 24/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MKNParameters.h"
#import "MKNApiAdapter.h"

@interface MeekanSDK : NSObject
@property (nonatomic, strong) id<ApiAdapter> apiAdapter;

+ (instancetype)sharedInstanceWithApiKey:(NSString *)apiKey;
+ (instancetype)sharedInstance;

- (id)initWithApiKey:(NSString *)apiKey;

- (void)createMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)success onError:(MeekanResponseError)error;
- (void)updateMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)success onError:(MeekanResponseError)error;
@end
