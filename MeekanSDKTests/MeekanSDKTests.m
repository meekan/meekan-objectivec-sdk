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
@property (nonatomic, strong) NSString *connectedAccount;
@end

@implementation MeekanSDKTests

- (void)setUp
{
    [super setUp];
    NSHTTPCookie *session = [NSHTTPCookie cookieWithProperties:
                             @{NSHTTPCookieName: @"session",
                               NSHTTPCookiePath: @"/",
                               NSHTTPCookieValue: @"eyJfbWVzc2FnZXMiOltbIldlbGNvbWUhICBZb3UgaGF2ZSBiZWVuIHJlZ2lzdGVyZWQgYXMgYSBuZXcgdXNlciBhbmQgbG9nZ2VkIGluIHRocm91Z2ggR29vZ2xlIE9BdXRoMi4iLCJzdWNjZXNzIl1dLCJzdGF0ZSI6IllFUlZUVTZRWDI3TkRWRlJZQ1paUUcySlNOUlE3UEhRIiwiZ29vZ2xlX29hdXRoMiI6IntcImZ1bGxfbmFtZVwiOiBcIkV5YWwgTWVla2FuXCIsIFwiaWRcIjogXCIxMTU3NjUxMzc1OTgwMTI3ODIzMTZcIiwgXCJmaXJzdF9uYW1lXCI6IFwiRXlhbFwiLCBcImxhc3RfbmFtZVwiOiBcIk1lZWthblwiLCBcImVtYWlsXCI6IFwiZXlhbEBtZWVrYW4uY29tXCJ9In0=|1409210860|871179f93c3b00f5a3d2e3f1869f15f873e35992",
                               NSHTTPCookieVersion: @"1",
                               NSHTTPCookieDomain: @"localhost"}];
    NSHTTPCookie *sessionName = [NSHTTPCookie cookieWithProperties:
                                 @{NSHTTPCookieName: @"session_name",
                                   NSHTTPCookiePath: @"/",
                                   NSHTTPCookieValue: @"eyJfdXNlciI6WzU2Mjk0OTk1MzQyMTMxMjAsMSwiVjZtbzRsTG5yaTRLZGltSmZGUnJDcCIsMTQwOTIxMDg1OSwxNDA5MjEwODU5XX0=|1409210865|9e9d4c9fd956b061b69d9ea98f11ca68c694043d",
                                   NSHTTPCookieVersion: @"1",
                                   NSHTTPCookieDomain: @"localhost"}];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:session];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:sessionName];
    self.sdk =[MeekanSDK sharedInstanceWithApiKey:@"AnyKey"];
    self.connectedAccount = @"4785074604081152";
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testCreateDraftMeeting
{

    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = self.connectedAccount;
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
    details.participants = [[MeetingParticipants alloc]init];
    
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

-(void)testCreateAndThenDeleteDraft {
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = @"4785074604081152";
    details.title = @"Test";
    details.durationInMinutes = 10;
    
    [self startAsyncTest];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        if (details.meetingId) {
            [self.sdk deleteMeeting:details.meetingId onSuccess:^(NSString *deletedMeekanId) {
                XCTAssertEqual(details.meetingId, deletedMeekanId, @"Deleted the correct meeting");
                [self endAsyncTest];
            } onError:^(NSError *err) {
                XCTFail(@"Unexpected error: %@", err);
                [self endAsyncTest];
            }];
        }
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    [self maximumDelayForAsyncTest:60];
}

-(void)testMeetingListIsReturnedWithOneMeetingAfterCreatingIt {
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = @"4785074604081152";
    details.title = @"Test";
    details.durationInMinutes = 10;
    
    [self startAsyncTest];
    NSDate *start = [NSDate date];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        NSString *newlyCreatedId = [details meetingId];
        [self.sdk listMeetingsForAccountSince:start onSuccess:^(MeetingList *meetingList) {
            XCTAssertTrue(!meetingList.hasMore, @"Returned all expected meetings");
            XCTAssertTrue([meetingList.meetings count] == 1, @"Expected only the meeting created after the test start");
            MeetingFromServer *meeting = meetingList.meetings[0];
            XCTAssertTrue([meeting meetingId], @"Expected only the meeting created after the test start");
            XCTAssertEqualObjects([meeting meetingId], newlyCreatedId, @"Expected same created meeting");
            [self endAsyncTest];
        } onError:^(NSError *err) {
            XCTFail(@"Unexpected error: %@", err);
            [self endAsyncTest];
        }];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    [self maximumDelayForAsyncTest:60];
}

-(void)testUserIsConnectedWithTestSession {
    [self startAsyncTest];

    [self.sdk connectedUserDetailsWithSuccess:^(ConnectedUser *user) {
        XCTAssertNotNil(user, @"Expected connected user");
        XCTAssertTrue([user.userId length] != 0, @"Expected user with Meekan ID, reeived empty value");
        XCTAssertTrue([user.accounts count] != 0, @"Expected user with accounts, received empty");
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];

    [self maximumDelayForAsyncTest:60];
}

-(void)testConnectUserWithExchange {
    [self startAsyncTest];
    // Disconnect from all accounts
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://localhost"]]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
    
    [self.sdk connectedUserDetailsWithSuccess:^(ConnectedUser *user) {
        XCTFail(@"Expected to be disconnected, received %@", user);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        NSDictionary *accountParams = [self readTestAccountWithId:@"exchange1"];
        [self.sdk connectWithExchangeUser:accountParams[@"username"] withPassword:accountParams[@"password"] withEmail:accountParams[@"email"] withServerUrl:accountParams[@"url"] andDomain:accountParams[@"domain"] onSuccess:^(ConnectedUser *user) {
            XCTAssertNotNil(user, @"Expected connected user");
            XCTAssertTrue([user.userId length] != 0, @"Expected user with Meekan ID, reeived empty value");
            XCTAssertTrue([user.accounts count] == 1, @"Expected user with one account, received %lu", [user.accounts count] );
            XCTAssertEqualObjects(user.primaryEmail, accountParams[@"email"], @"Expected same email address as registered");
            [self endAsyncTest];
        } onError:^(NSError *err) {
            XCTFail(@"Unexpected error: %@", err);
            [self endAsyncTest];
        }];
    }];
    
    
    [self maximumDelayForAsyncTest:60];
}

-(void)testSuggestedSlotsEmptyFrames {
    [self startAsyncTest];

    SlotSuggestionsRequest *request = [[SlotSuggestionsRequest alloc]init];
    request.organizerAccountId = self.connectedAccount;
    request.duration = 10; // Minutes
    [self.sdk suggestedSlots:request onSuccess:^(NSArray *slotSuggestions) {
        XCTAssertEqual([slotSuggestions count], 0, @"Without frames, expected zero suggestions, received %ld: %@", [slotSuggestions count], slotSuggestions);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    
    [self maximumDelayForAsyncTest:60];
}

-(void)testSuggestedSlotsFrameWithSingleSpot {
    [self startAsyncTest];
    
    SlotSuggestionsRequest *request = [[SlotSuggestionsRequest alloc]init];
    request.organizerAccountId = self.connectedAccount;
    request.duration = 10; // Minutes
    NSDate *now = [NSDate date];
    request.timeFrameRanges = @[ @[now, [now dateByAddingTimeInterval:10 * 60]] ];
    [self.sdk suggestedSlots:request onSuccess:^(NSArray *slotSuggestions) {
        XCTAssertEqual([slotSuggestions count], 1, @"With single tight frame, expected one suggestion, received %ld: %@", [slotSuggestions count], slotSuggestions);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    
    [self maximumDelayForAsyncTest:60];
}

-(NSDictionary *)readTestAccountWithId:(NSString *)accountId {
    NSString *plistPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"testAccounts" ofType:@"plist"];
    NSDictionary *accounts = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    return [accounts objectForKey:accountId];
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
