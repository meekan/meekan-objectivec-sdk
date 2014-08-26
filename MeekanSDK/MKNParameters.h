//
//  MeekanParameters.h
//  MeekanSDK
//
//  Created by Eyal Yavor on 24/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MeetingDetails;
@class MeetingParticipants;
@class MeetingLocation;
@class MeetingServerResponse;

static NSString *MEEKAN_CLIENT_ERROR_DOMAIN = @"MeekanSDK";

NS_ENUM(NSInteger, SDKErrorCodes) {
    NOT_IMPLEMENTED_IN_THIS_SDK = -1,
    MISSING_RESPONSE_BODY = -2,
    UNEXPECTED_RESPONSE_FORMAT = -3,
    INVALID_PARAMETERS = -4
};

typedef void (^MeekanResponseError)(NSError *err);

typedef void (^MeetingResponseSuccess)(MeetingServerResponse *details);



typedef NS_ENUM(NSUInteger, RepeatInterval) {
    NEVER = 0,
    DAILY = 1,
    WEEKLY = 7,
    BIWEEKLY = 14,
    MONTHLY = 31,
    YEARLY = 365
};

typedef NS_ENUM(NSUInteger, MeetingVote) {
    NOT_YET = 0,
    CUSTOM = 1,
    ALWAYS = 2,
    WHEN_AVAILABLE = 3,
    NOT_COMING = 4,
    MAYBE = 5
};

@interface ApiParameter : NSObject
-(id)initFromJson:(NSDictionary *)jsonDictionary;
-(NSDictionary *)toJson;
-(NSDictionary *)toJsonWithOnly:(NSSet *)keysToInclude;
@end

@interface MeetingDetails : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic) NSInteger durationInMinutes;
@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *calendarInAccount;

@property (nonatomic, strong) NSSet *options;

@property (nonatomic, strong) MeetingLocation *location;
@property (nonatomic, strong) MeetingParticipants *participants;

@property (nonatomic) NSString *timeSlotDescription;
@property (nonatomic, strong) NSArray *slots;

@property (nonatomic) NSInteger reminderMinutesBefore;
@property (nonatomic, strong) NSString *reminderMethod;

@property (nonatomic) RepeatInterval repeatInterval;

@property (nonatomic) NSString *timezone;
@end

@interface MeetingParticipants : NSObject
@property (nonatomic, strong) NSSet *emails;
@property (nonatomic, strong) NSSet *phoneNumbers;
@property (nonatomic, strong) NSSet *meekanIds;
@end

@interface MeetingLocation : NSObject
@property (nonatomic, strong) NSString *shortDesc;
@property (nonatomic, strong) NSString *address;
@property (nonatomic) double longitude;
@property (nonatomic) double latitude;
@end

@interface MeetingServerResponse : NSObject
@property (nonatomic, strong) NSString *meetingId;
/**
 Array consisting of @[@{
 remote_id: "csiebq26o9l0rdibbvc5peloso", // ID of the created event on the calendar endpoint
 start: 1404282883,                       // Timestamp of the created event
 duration: 60                             // Duration of the event
 }, ...]
 */
@property (nonatomic, strong) NSArray *remoteEventIds;
@end
