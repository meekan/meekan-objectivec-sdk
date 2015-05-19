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
@class ConnectedUser;
@class MeetingList;

extern NSString *const kMKNClientErrorDomain;
extern NSString *const kMKNTimeRangeStartKey;
extern NSString *const kMKNTimeRangeEndKey;

NS_ENUM(NSInteger, SDKErrorCodes) {
    NOT_IMPLEMENTED_IN_THIS_SDK = -1,
    MISSING_RESPONSE_BODY = -2,
    UNEXPECTED_RESPONSE_FORMAT = -3,
    INVALID_PARAMETERS = -4
};

typedef void (^MeekanResponseError)(NSError *err);

typedef void (^MeetingResponseSuccess)(MeetingServerResponse *details);
typedef void (^MeetingDeleteSuccess)(NSString *deletedMeekanId);
typedef void (^ConnectedUserSuccess)(ConnectedUser *user);
typedef void (^MeetingListSuccess)(MeetingList *meetingList);
typedef void (^SlotListSuccess)(NSArray *slotSuggestions);
typedef void (^FreeBusySuccess)(NSArray *freeBusyRanges);
typedef void (^MeekanIdLookupSuccess)(NSDictionary *identifiersToMeekanId);
typedef void (^MeetingPollVoteSuccess)(NSString *meetingId, NSString *accountId);


typedef NS_ENUM(NSUInteger, RepeatInterval) {
    NEVER = 0,
    DAILY = 1,
    WEEKLY = 7,
    BIWEEKLY = 14,
    MONTHLY = 31,
    YEARLY = 365
};

typedef NS_ENUM(NSUInteger, PollVote) {
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

@interface ConnectedAccount : NSObject
@property (nonatomic, strong) NSString *meekanId;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic, strong) NSString *accountType;
@property (nonatomic, strong) NSString *name;
@end

@interface ConnectedUser: NSObject
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *primaryEmail;
@property (nonatomic, strong) NSArray *accounts;
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
 Array of MeetingRemoteEvent
 Array consisting of @[@{
 remote_id: "csiebq26o9l0rdibbvc5peloso", // ID of the created event on the calendar endpoint
 start: 1404282883,                       // Timestamp of the created event
 duration: 60                             // Duration of the event
 }, ...]
 */
@property (nonatomic, strong) NSArray *remoteEventIds;
@end

@interface MeetingRemoteEvent : NSObject
@property (nonatomic, strong) NSString *remoteId;
@property (nonatomic, strong) NSDate *start;
@property (nonatomic) NSUInteger duration;
@end

@interface MeetingFromServer : NSObject
@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, strong) NSDate *createTime;
@property (nonatomic, strong) NSString *meetingId;
@property (nonatomic) BOOL isDeleted;
@property (nonatomic, strong) MeetingDetails *details;
@property (nonatomic, strong) NSArray *remoteIds;
@property (nonatomic, strong) NSDictionary *votes;
@property (nonatomic, strong) NSString *organizerEmail;
@end

@interface MeetingList : NSObject
/** The NSArray contains `MeetingFromServer`s */
@property (nonatomic, strong) NSArray *meetings;
@property (nonatomic) BOOL hasMore;
@end

@interface MeetingVote : NSObject

@property (nonatomic, strong) NSDate *lastUpdate;
@property (nonatomic, strong) NSSet *preferredTimes;
@property (nonatomic) PollVote vote;
@property (nonatomic, strong) NSString *accountId;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) NSString *phone;
@end


@interface SlotSuggestionsRequest : NSObject
@property (nonatomic, strong) NSSet *inviteesIds;
@property (nonatomic) NSUInteger duration;
@property (nonatomic, strong) NSString *organizerAccountId;
@property (nonatomic, strong) NSArray *timeFrameRanges;
@property (nonatomic, strong) NSString *locationLatLong;
@property (nonatomic, strong) NSString *timezone;
@property (nonatomic) BOOL useLocationPadding;
@property (nonatomic) NSInteger page;
@end

@interface MeetingOverview : NSObject
@property (nonatomic, strong) NSString *meetingName;
@property (nonatomic, strong) NSDate *start;
@property (nonatomic) NSUInteger duration;
@end

@interface SlotSuggestion : NSObject
@property (nonatomic, strong) NSDate *start;
@property (nonatomic, strong) NSSet *busyIds;
@property (nonatomic) NSInteger rank;
@property (nonatomic) NSTimeInterval paddingBefore;
@property (nonatomic) NSTimeInterval paddingAfter;
@property (nonatomic, strong) MeetingOverview *meetingBefore;
@property (nonatomic, strong) MeetingOverview *meetingAfter;
@end
