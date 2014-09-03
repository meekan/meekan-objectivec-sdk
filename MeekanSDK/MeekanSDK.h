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
#import "MKNGoogleLoginViewController.h"

@interface MeekanSDK : NSObject
@property (nonatomic, strong) id<ApiAdapter> apiAdapter;

+ (instancetype)sharedInstanceWithApiKey:(NSString *)apiKey;
+ (instancetype)sharedInstanceWithApiKey:(NSString *)apiKey andBaseUrl:(NSString *)baseUrl;
+ (instancetype)sharedInstance;
- (id)initWithApiKey:(NSString *)apiKey;
- (id)initWithApiKey:(NSString *)apiKey andBaseUrl:(NSString *)baseUrl;

- (MKNGoogleLoginViewController *)connectWithGoogleWithCompletionHandler:(MKNGoogleLoginViewControllerCompletionHandler)completion;
- (void)connectWithExchangeUser:(NSString *)username withPassword:(NSString *)password withEmail:(NSString *)email withServerUrl:(NSString *)url andDomain:(NSString *)domain onSuccess:(ConnectedUserSuccess)success onError:(MeekanResponseError)error;

- (void)connectedUserDetailsWithSuccess:(ConnectedUserSuccess)success onError:(MeekanResponseError)error;


- (void)queryForMeekanIdsOfIdentifiers:(NSSet *)identifiers onSuccess:(MeekanIdLookupSuccess)success onError:(MeekanResponseError)error;

- (void)createMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)success onError:(MeekanResponseError)error;
- (void)updateMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)success onError:(MeekanResponseError)error;
- (void)deleteMeeting:(NSString *)meetingId onSuccess:(MeetingDeleteSuccess)success onError:(MeekanResponseError)error;
- (void)listMeetingsForAccountSince:(NSDate *)timestamp onSuccess:(MeetingListSuccess)success onError:(MeekanResponseError)error;

- (void)suggestedSlots:(SlotSuggestionsRequest *)request onSuccess:(SlotListSuccess)success onError:(MeekanResponseError)error;

- (void)freeBusyFor:(NSString *)account fromDate:(NSDate *)startDate untilDate:(NSDate *)endDate onSuccess:(FreeBusySuccess)success onError:(MeekanResponseError)error;

@end
