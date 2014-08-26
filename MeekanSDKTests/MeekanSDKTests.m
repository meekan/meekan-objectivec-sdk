//
//  MeekanSDKTests.m
//  MeekanSDK
//
//  Created by Eyal Yavor on 25/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MeekanSDK.h"
//#import "MeekanSDK/MKNApiAdapter.h"
//#import "MeekanSDK/MKNParameters.h"

static BOOL hasEntered;

@interface MeekanSDKTests : XCTestCase
@property (nonatomic, strong) MeekanSDK *sdk;
@end

@implementation MeekanSDKTests

- (void)setUp
{
    [super setUp];
    NSHTTPCookie *session = [NSHTTPCookie cookieWithProperties:
                             @{NSHTTPCookieName: @"session",
                               NSHTTPCookiePath: @"/",
                               NSHTTPCookieValue: @"eyJnb29nbGVfb2F1dGgyIjoie1wibGFzdF9uYW1lXCI6IFwiTWVla2FuXCIsIFwiZW1haWxcIjogXCJleWFsQG1lZWthbi5jb21cIiwgXCJmdWxsX25hbWVcIjogXCJFeWFsIE1lZWthblwiLCBcImlkXCI6IFwiMTE1NzY1MTM3NTk4MDEyNzgyMzE2XCIsIFwiZmlyc3RfbmFtZVwiOiBcIkV5YWxcIn0iLCJfbWVzc2FnZXMiOltbIldlbGNvbWUhICBZb3UgaGF2ZSBiZWVuIHJlZ2lzdGVyZWQgYXMgYSBuZXcgdXNlciBhbmQgbG9nZ2VkIGluIHRocm91Z2ggR29vZ2xlIE9BdXRoMi4iLCJzdWNjZXNzIl1dfQ==|1409040847|19cb45250f110ca0ecbff3c63344e49a0f87bfe5",
                               NSHTTPCookieVersion: @"1",
                               NSHTTPCookieDomain: @"localhost"}];
    NSHTTPCookie *sessionName = [NSHTTPCookie cookieWithProperties:
                                 @{NSHTTPCookieName: @"session_name",
                                   NSHTTPCookiePath: @"/",
                                   NSHTTPCookieValue: @"eyJfdXNlciI6WzU2Mjk0OTk1MzQyMTMxMjAsMSwiZkM1cHFiaVRNYnJJdWlrdXdWak1mZiIsMTQwOTA0MDg0NiwxNDA5MDQwODQ2XX0=|1409040918|264c90c68a84e02582f8cff09fa2a051d14d03e1",
                                   NSHTTPCookieVersion: @"1",
                                   NSHTTPCookieDomain: @"localhost"}];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:session];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:sessionName];
    self.sdk =[MeekanSDK sharedInstanceWithApiKey:@"AnyKey"];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateDraftMeeting
{

    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = @"4785074604081152";
    details.title = @"Test";
    details.durationInMinutes = 10;
    
    [self startAsyncTest];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        XCTAssertNotNil(details, @"Expected returned details");
        XCTAssertNotNil(details.meetingId, @"Expected Created meeting ID");
        XCTAssertNotNil(details.remoteEventIds, @"Expected non-empty remote list");
        XCTAssertTrue([details.remoteEventIds count] == 0, @"Should not create remote meetings, returned: %@", details.remoteEventIds);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    [self maximumDelayForAsyncTest:60];
}


- (void)testCreateSingleMeeting
{
    
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = @"4785074604081152";
    details.title = @"Test Single";
    details.durationInMinutes = 10;
    details.options = [NSSet setWithObject:[NSDate date]];
    
    [self startAsyncTest];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        XCTAssertNotNil(details, @"Expected returned details");
        XCTAssertNotNil(details.meetingId, @"Expected Created meeting ID");
        XCTAssertNotNil(details.remoteEventIds, @"Expected non-empty remote list");
        XCTAssertTrue([details.remoteEventIds count] == 1, @"Should create single remote meeting, returned: %@", details.remoteEventIds);
        [self assertValidRemoteMeeting:[details.remoteEventIds firstObject]];
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    [self maximumDelayForAsyncTest:60];
}

- (void)testCreateMultipleMeeting
{
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = @"4785074604081152";
    details.title = @"Test Multiple";
    details.durationInMinutes = 10;
    NSDate *start = [NSDate dateWithTimeIntervalSince1970:1409477400];
    NSSet *options = [NSSet setWithObjects:
                        [start dateByAddingTimeInterval:3600],
                        [start dateByAddingTimeInterval:7200],
                        [start dateByAddingTimeInterval:10800], nil];
    details.options = options;
    
    [self startAsyncTest];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        XCTAssertNotNil(details, @"Expected returned details");
        XCTAssertNotNil(details.meetingId, @"Expected Created meeting ID");
        XCTAssertNotNil(details.remoteEventIds, @"Expected non-empty remote list");
        XCTAssertTrue([details.remoteEventIds count] == [options count],
                      @"Should create %lu remote meetings, returned: %@", (unsigned long)[options count], details.remoteEventIds);
        for (NSDictionary *remoteEvent in details.remoteEventIds) {
            [self assertValidRemoteMeeting:remoteEvent];
            NSDate *start = [NSDate dateWithTimeIntervalSince1970:[[remoteEvent objectForKey:@"start"] integerValue]];

            XCTAssertTrue([options containsObject:start], @"Scheduled time [%@] should be in the requested times: %@", start, options);
        }
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    [self maximumDelayForAsyncTest:60];
}

- (void)assertValidRemoteMeeting:(id)remoteMeeting {
    XCTAssertTrue([remoteMeeting isKindOfClass:[NSDictionary class]], @"Expected remote meeting to be a dictionary");
    NSDictionary *remote = remoteMeeting;
    XCTAssertNotNil([remote objectForKey:@"remote_id"], @"Expected remote meeting to have a remote id");
    XCTAssertTrue([remote objectForKey:@"start"], @"Expected remote meeting to contain start time");
    XCTAssertTrue([remote objectForKey:@"duration"], @"Expected remote meeting to contain duration");
}


- (void) startAsyncTest
{
    hasEntered = NO;
}

- (void) endAsyncTest
{
    hasEntered = YES;
}

- (void)maximumDelayForAsyncTest:(NSInteger)maxDelay
{
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:maxDelay];
    while (hasEntered == NO && [loopUntil timeIntervalSinceNow] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }
    
    if (hasEntered != YES) {
        XCTFail(@"Return of async call never reached");
    }
}

@end
