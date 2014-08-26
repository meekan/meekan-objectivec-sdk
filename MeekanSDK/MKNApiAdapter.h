//
//  ApiV1Adapter.h
//  MeekanSDK
//
//  Created by Eyal Yavor on 24/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

@import Foundation;

#import "MKNParameters.h"

@interface HTTPEndpoint : NSObject
@property NSString *path;
@property NSDictionary *parameters;
@end

@protocol ApiAdapter <NSObject>
- (NSError *)checkIfError:(id)baseResult;

@optional
- (HTTPEndpoint *)createMeetingUsing:(MeetingDetails *)details;
/**
 Parses the result into an object. If there is an error, returns nil and in the NSError
 */
- (MeetingServerResponse *)parseCreateMeetingResponseFrom:(id)serverResponse andError:(NSError * __autoreleasing *)error;
@end

@interface ApiV1Adapter : NSObject <ApiAdapter>
@end

