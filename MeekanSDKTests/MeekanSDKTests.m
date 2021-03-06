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
@property (nonatomic, strong) NSMutableSet *danglingMeetings;
@end

@implementation MeekanSDKTests

- (void)setUp
{
    [super setUp];
    [self connectAsGoogleAccount];
    self.sdk =[MeekanSDK sharedInstanceWithApiKey:@"AnyKey" andBaseUrl:@"http://localhost:8080"];
    self.connectedAccount = @"4993981813358592";
    self.danglingMeetings = [NSMutableSet set];
}

- (void)tearDown
{
    if ([self.danglingMeetings count]) {
        [self startAsyncTest];
        [self deleteDanglingMeetings];
        [self maximumDelayForAsyncTest:60];
    } else {
        [self deleteCurrentCookies];
        [super tearDown];
    }
}

-(void)deleteDanglingMeetings {
    NSInteger __block pending = [self.danglingMeetings count];
    for (NSString *meetingId in self.danglingMeetings) {
        [self.sdk deleteMeeting:meetingId onSuccess:^(NSString *deletedMeekanId) {
            pending--;
            if (pending == 0) {
                [self deleteCurrentCookies];
                [self endAsyncTest];
            }
        } onError:^(NSError *err) {
            pending--;
            if (pending == 0) {
                [self deleteCurrentCookies];
                [self endAsyncTest];
            }
            // Do Nothing
        }];
    }
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
        [self.danglingMeetings addObject:details.meetingId];
        XCTAssertNotNil(details.remoteEventIds, @"Expected non-empty remote list");
        XCTAssertTrue([details.remoteEventIds count] == 0, @"Should not create remote meetings, returned: %@", details.remoteEventIds);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    [self maximumDelayForAsyncTest:60];
}


- (void)testLooukpExistingIdentifierShouldReturnIt {
    [self startAsyncTest];
    
    [self.sdk queryForMeekanIdsOfIdentifiers:[NSSet setWithObject:@"eyal.yavor@gmail.com"] onSuccess:^(NSDictionary *identifiersToMeekanId) {
        XCTAssertEqualObjects([identifiersToMeekanId objectForKey:@"eyal.yavor@gmail.com"], self.connectedAccount, @"Expected current account to be recognized");
        [self endAsyncTest];

    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    
    [self maximumDelayForAsyncTest:60];
}

- (void)testLooukpNonExistingIdentifierShouldNotReturnIt {
    [self startAsyncTest];
    
    [self.sdk queryForMeekanIdsOfIdentifiers:[NSSet setWithObject:@"bobdylan@gmail.com"] onSuccess:^(NSDictionary *identifiersToMeekanId) {
        XCTAssertNil([identifiersToMeekanId objectForKey:@"bobdylan@gmail.com"] , @"Expected account not to be recognized");
        [self endAsyncTest];
        
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    
    [self maximumDelayForAsyncTest:60];
}

- (void)testLooukpBothExistingAndNotExistingIdentifiersShouldReturnOnlyRealOnes {
    [self startAsyncTest];
    
    [self.sdk queryForMeekanIdsOfIdentifiers:[NSSet setWithObjects:@"bobdylan@gmail.com",@"eyal.yavor@gmail.com", nil] onSuccess:^(NSDictionary *identifiersToMeekanId) {
        XCTAssertEqual([identifiersToMeekanId count], 1, @"Expected only one account to be recognized");
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
    details.accountId = self.connectedAccount;
    details.title = @"Test Single";
    details.durationInMinutes = 10;
    details.options = [NSSet setWithObject:[NSDate date]];
    
    [self startAsyncTest];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        XCTAssertNotNil(details, @"Expected returned details");
        XCTAssertNotNil(details.meetingId, @"Expected Created meeting ID");
        [self.danglingMeetings addObject:details.meetingId];
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
    details.accountId = self.connectedAccount;
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
        [self.danglingMeetings addObject:details.meetingId];
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
    details.accountId = self.connectedAccount;
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
    details.accountId = self.connectedAccount;
    details.title = @"Test";
    details.durationInMinutes = 10;
    
    [self startAsyncTest];
    NSDate *start = [NSDate date];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        NSString *newlyCreatedId = [details meetingId];
        [self.danglingMeetings addObject:details.meetingId];
        [self.sdk listMeetingsForAccountSince:start onSuccess:^(MeetingList *meetingList) {
            XCTAssertTrue(!meetingList.hasMore, @"Returned all expected meetings");
            XCTAssertEqual([meetingList.meetings count], 1, @"Expected only the meeting created after the test start");
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
    
    [self deleteCurrentCookies];
    
    [self.sdk connectedUserDetailsWithSuccess:^(ConnectedUser *user) {
        XCTFail(@"Expected to be disconnected, received %@", user);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        [self connectAsTestExchangeOnSuccess:^(ConnectedUser *user) {
            NSDictionary *accountParams = [self readTestAccountWithId:@"exchange1"];
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
        SlotSuggestion *suggestion = slotSuggestions[0];
        XCTAssertEqual(suggestion.start, now, @"Only possible time should've been %@, but received %@", now, suggestion.start);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    
    [self maximumDelayForAsyncTest:60];
}

-(void)testSuggestedSlotsFrameWithMultipleFrames {
    [self startAsyncTest];
    
    SlotSuggestionsRequest *request = [[SlotSuggestionsRequest alloc]init];
    request.organizerAccountId = self.connectedAccount;
    request.duration = 10; // Minutes
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:trunc([[NSDate date] timeIntervalSince1970])];
    request.timeFrameRanges = @[ @[now, [now dateByAddingTimeInterval:10 * 60]],
                                 @[[now dateByAddingTimeInterval:20*60], [now dateByAddingTimeInterval:30*60]]];
    NSSet *framesStart = [NSSet setWithObjects:now, [now dateByAddingTimeInterval:20*60],nil];
    [self.sdk suggestedSlots:request onSuccess:^(NSArray *slotSuggestions) {
        NSSet *times = [NSSet setWithArray:[slotSuggestions valueForKey:@"start"]];
        XCTAssertEqual([times count], 2, @"With two tight frames, expected two suggestions, received %ld: %@", [times count], slotSuggestions);
        XCTAssertTrue([times isEqualToSet:framesStart], @"Only possible time should've been %@, but received %@", times, framesStart);
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTFail(@"Unexpected error: %@", err);
        [self endAsyncTest];
    }];
    
    [self maximumDelayForAsyncTest:60];
}

-(void)testSuggestedSlotsFrameWithDrivingTime {
    [self startAsyncTest];
    
    MeetingLocation *location1 = [[MeetingLocation alloc]init];
    location1.latitude = 32.086480f;
    location1.longitude = 34.782296f;
    location1.shortDesc = @"Tel Aviv Office";
    
    NSDate *scenarioStart = [NSDate dateWithTimeIntervalSince1970:trunc([[NSDate date] timeIntervalSince1970])+180*60];
    NSDateComponents *comps = [[NSCalendar currentCalendar]components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit fromDate:scenarioStart];
    [comps setMinute:60];
    [comps setSecond:0];
    scenarioStart = [[NSCalendar currentCalendar]dateFromComponents:comps];
    
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = self.connectedAccount;
    details.title = @"In Tel Aviv";
    details.durationInMinutes = 10;
    details.options = [NSSet setWithObject:scenarioStart];
    details.location = location1;
    
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *details) {
        //      [self.danglingMeetings addObject:details.meetingId];
        SlotSuggestionsRequest *request = [[SlotSuggestionsRequest alloc]init];
        request.organizerAccountId = self.connectedAccount;
        request.duration = 10; // Minutes
        request.timeFrameRanges = @[ @[ [scenarioStart dateByAddingTimeInterval:-120*60], [scenarioStart dateByAddingTimeInterval:120 * 60]]]; // One big range of three hours around the meeting, for a 10 minutes meeting
        request.locationLatLong = @"32.159171,34.808994";
        request.useLocationPadding = YES;
        
        [self.sdk suggestedSlots:request onSuccess:^(NSArray *slotSuggestions) {
            XCTAssertGreaterThan([slotSuggestions count], 0, @"With a big grame, expected at least one suggestion, received %ld: %@", [slotSuggestions count], slotSuggestions);
            BOOL atLeastOneHadPadding = NO;
            for (SlotSuggestion *suggestion in slotSuggestions) {
                atLeastOneHadPadding |= [suggestion paddingAfter] || [suggestion paddingBefore];
            }
            XCTAssertTrue(atLeastOneHadPadding, @"Slot suggestion expected to have padding, but didn't: %@", slotSuggestions);
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

-(void)testFreeBusyWithBadParameters {
    [self startAsyncTest];
    
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:trunc([[NSDate date] timeIntervalSince1970])];
    [self.sdk freeBusyFor:self.connectedAccount fromDate:[now dateByAddingTimeInterval:600] untilDate:now onSuccess:^(NSArray *freeBusyRanges) {
        XCTFail(@"Should have failed before time ranges are reversed");
        [self endAsyncTest];
    } onError:^(NSError *err) {
        XCTAssertEqual(err.code, INVALID_PARAMETERS,@"Expected failure for invalid parameters");
        [self endAsyncTest];
    }];
    
    [self maximumDelayForAsyncTest:60];
}

-(void)testVoteForMeetingFromConnectedAccount {
    
    // As Google
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = self.connectedAccount;
    details.title = @"Test Multiple";
    details.durationInMinutes = 10;
    NSDate *start = [NSDate dateWithTimeIntervalSince1970:1409477400];
    NSSet *options = [NSSet setWithObjects:
                      [start dateByAddingTimeInterval:3600],
                      [start dateByAddingTimeInterval:7200],
                      [start dateByAddingTimeInterval:10800], nil];
    details.options = options;
    details.participants = [[MeetingParticipants alloc]init];
    NSDictionary *accountDetails = [self readTestAccountWithId:@"exchange1"];
    details.participants.emails = [NSSet setWithObject:accountDetails[@"email"]];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *response) {
        [self connectAsTestExchangeOnSuccess:^(ConnectedUser *user) {
            
            ConnectedAccount *invitedAccount = [[[user accounts] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF.identifier = %@", accountDetails[@"email"]]] firstObject];
            XCTAssertNotNil(invitedAccount, @"The invited account is supposed to be in this user");
            NSDate *beforeVote = [NSDate date];
            NSSet *preferredTimes = [NSSet setWithObject:[start dateByAddingTimeInterval:10800]];
            [self.sdk voteForMeeting:response.meetingId asAccount:invitedAccount.meekanId withVote:CUSTOM andPreferredTimes:preferredTimes
                           onSuccess:^(NSString *meetingId, NSString *accountId) {
                XCTAssertEqualObjects(meetingId, response.meetingId, @"Expected response for same meeting");
                XCTAssertEqualObjects(accountId, invitedAccount.meekanId, @"Expected response for same account");
                
                [self connectAsGoogleAccount];
                [self.sdk listMeetingsForAccountSince:beforeVote onSuccess:^(MeetingList *meetingList) {
                    BOOL foundMeeting = NO;
                    for (MeetingFromServer *meeting in meetingList.meetings) {
                        if ([meeting.meetingId isEqualToString:response.meetingId]) {
                            foundMeeting = YES;
                            XCTAssertNotNil([meeting.votes objectForKey:invitedAccount.meekanId], @"Expected to contain invited user's vote");
                            MeetingVote *vote = meeting.votes[invitedAccount.meekanId];
                            XCTAssertEqual([vote vote], CUSTOM, @"Expected same vote as sent before");
                            XCTAssertTrue([[vote preferredTimes] isEqualToSet:preferredTimes], @"Expected returned preferences to be %@, received %@", preferredTimes, vote.preferredTimes);
                        }
                    }
                    XCTAssertTrue(foundMeeting, @"Expected changes in the meeting since we voted on it");
                    [self endAsyncTest];
                } onError:^(NSError *err) {
                    XCTFail(@"Unexpected error: %@", err);
                    [self endAsyncTest];
                }];
                
            } onError:^(NSError *err) {
                XCTFail(@"Unexpected error: %@", err);
                [self endAsyncTest];
            }];
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

-(void)deleteCurrentCookies {
    for (NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:@"http://localhost"]]) {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }
}

-(void)connectAsGoogleAccount {
    [self deleteCurrentCookies];
    NSHTTPCookie *session = [NSHTTPCookie cookieWithProperties:
                             @{NSHTTPCookieName: @"session",
                               NSHTTPCookiePath: @"/",
                               NSHTTPCookieValue: @"eyJnb29nbGVfb2F1dGgyIjoie1wiZW1haWxcIjogXCJleWFsLnlhdm9yQGdtYWlsLmNvbVwiLCBcImZ1bGxfbmFtZVwiOiBcIkV5YWwgWWF2b3JcIiwgXCJpZFwiOiBcIjEwODE0Nzc1OTA0ODY2NzMzOTkwOFwiLCBcImZpcnN0X25hbWVcIjogXCJFeWFsXCIsIFwibGFzdF9uYW1lXCI6IFwiWWF2b3JcIn0iLCJfbWVzc2FnZXMiOltbIldlbGNvbWUhICBZb3UgaGF2ZSBiZWVuIHJlZ2lzdGVyZWQgYXMgYSBuZXcgdXNlciBhbmQgbG9nZ2VkIGluIHRocm91Z2ggR29vZ2xlIE9BdXRoMi4iLCJzdWNjZXNzIl1dfQ\075\075|1421942880|8fb927398fc0a74969163b43b803ce15c3044406",
                               NSHTTPCookieVersion: @"1",
                               NSHTTPCookieDomain: @"localhost"}];
    NSHTTPCookie *sessionName = [NSHTTPCookie cookieWithProperties:
                                 @{NSHTTPCookieName: @"session_name",
                                   NSHTTPCookiePath: @"/",
                                   NSHTTPCookieValue: @"eyJfdXNlciI6WzU4Mzg0MDY3NDM0OTA1NjAsMSwiTENNQlVybE10bWJrMkVNQUNycGlsQSIsMTQyMTk0Mjg3OCwxNDIyMDk2NDg1XX0\075|1422096486|abd87fc29cbc8c13aecdd33c21d7f3f22206e85c",
                                   NSHTTPCookieVersion: @"1",
                                   NSHTTPCookieDomain: @"localhost"}];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:session];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:sessionName];
}

-(void)connectAsTestExchangeOnSuccess:(ConnectedUserSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    [self deleteCurrentCookies];
    NSDictionary *accountParams = [self readTestAccountWithId:@"exchange1"];
    [self.sdk connectWithExchangeUser:accountParams[@"username"] withPassword:accountParams[@"password"] withEmail:accountParams[@"email"] withServerUrl:accountParams[@"url"] andDomain:accountParams[@"domain"] onSuccess:successCallback onError:errorCallback];
}

-(void)testFreeBusyForValidBusyRange {
    [self startAsyncTest];
    
    NSDate *now = [NSDate dateWithTimeIntervalSince1970:trunc([[NSDate date] timeIntervalSince1970])];
    NSDate *inAnHour = [now dateByAddingTimeInterval:3600];
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.accountId = self.connectedAccount;
    details.title = @"Test FreeBusy";
    details.durationInMinutes = 10;
    details.options = [NSSet setWithObject:inAnHour];
    [self.sdk createMeeting:details onSuccess:^(MeetingServerResponse *response) {
        // Created the meeting
        [self.danglingMeetings addObject:response.meetingId];
        [self.sdk freeBusyFor:self.connectedAccount fromDate:now untilDate:[inAnHour dateByAddingTimeInterval:[details durationInMinutes] * 60] onSuccess:^(NSArray *busyRanges) {
            BOOL foundIt = NO;
            NSDate *meetingEndTime = [inAnHour dateByAddingTimeInterval:[details durationInMinutes] * 60];
            for (NSDictionary *range in busyRanges) {
                NSComparisonResult meetingToRangeStart = [inAnHour compare:range[kMKNTimeRangeStartKey]];
                NSComparisonResult meetingEndToRangeEnd = [meetingEndTime compare:range[kMKNTimeRangeEndKey]];
                foundIt |=
                 meetingToRangeStart != NSOrderedAscending &&
                 meetingEndToRangeEnd != NSOrderedDescending;
            }
            XCTAssertTrue(foundIt, @"Expected to find the created meeting range in the busy times");
            // The meeting duration must be included in one of the returned ranges
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
