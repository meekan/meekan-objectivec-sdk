//
//  ApiV1Adapter.m
//  MeekanSDK
//
//  Created by Eyal Yavor on 24/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import "MKNApiAdapter.h"
#import "MKNParameters.h"
#import "NSObject+TimeRanges.h"

static const NSTimeInterval THREE_MONTHS = 3 * 30 * 24 * 60 * 60;
static const NSTimeInterval MAX_RANGE_FOR_FREEBUSY = THREE_MONTHS;

@implementation HTTPEndpoint
@end

@implementation ApiV1Adapter

-(NSError *)checkIfError:(id)baseResult {
    NSError *err = nil;
    if (baseResult != nil) {
        if ([baseResult isKindOfClass:[NSDictionary class]]) {
            NSInteger errorCode = [[baseResult objectForKey:@"error_code"] integerValue];
            if (errorCode != 0) {
                NSString *errorMessage = [baseResult objectForKey:@"error_message"];
                err = [NSError errorWithDomain:kMKNClientErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage ? errorMessage : @"Server Error"}];
            }
        } else {
            err = [NSError errorWithDomain:kMKNClientErrorDomain code:UNEXPECTED_RESPONSE_FORMAT
                                  userInfo:@{NSLocalizedDescriptionKey:
                                                 NSLocalizedString(@"Expected Body to be a dictionary", nil)}];
        }
    } else {
        err = [NSError errorWithDomain:kMKNClientErrorDomain code:MISSING_RESPONSE_BODY
                              userInfo:@{NSLocalizedDescriptionKey:
                                             NSLocalizedString(@"Expected Response body, received empty", nil)}];
    }
    return err;
}

-(HTTPEndpoint *)identifiersToMeekanId:(NSSet *)identifiers {
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    endpoint.path = @"/rest/accounts";
    if ([identifiers count]) {
        endpoint.parameters = @{@"q": identifiers};
    }
    return endpoint;
}

-(HTTPEndpoint *)createMeetingUsing:(MeetingDetails *)details {
    return [self endpointForMeetingDetails:details];
}

-(HTTPEndpoint *)endpointForMeetingDetails:(MeetingDetails *)details {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    
    if ([details.accountId length] == 0 || details.durationInMinutes == 0) {
        return nil;
    }
    
    [self setValue:details.accountId toKey:@"account_id" inParameters:params];
    [self setValue:details.title toKey:@"meeting_name" inParameters:params];
    [self setValue:details.calendarInAccount toKey:@"calendar_id" inParameters:params];
    [self setValue:details.timezone toKey:@"timezone" inParameters:params];
    
    [params setObject:@(details.reminderMinutesBefore) forKey:@"reminder_minutes_before"];
    [self setValue:details.reminderMethod toKey:@"reminder_method" inParameters:params];
    
    [params setObject:@(details.repeatInterval) forKey:@"repeat_interval"];
    
    [self setValue:details.timeSlotDescription toKey:@"time_slots_desc" inParameters:params];
    if ([details.slots count]) {
        [params setObject:details.slots forKey:@"slot"];
    }
    
    [params setObject:@(details.durationInMinutes) forKey:@"duration"];
    
    if ([details.options count]) {
        [params setObject:[self timestampsFromDates:details.options] forKey:@"opt"];
    }
    
    if (details.location) {
        [self setValue:details.location.shortDesc toKey:@"location_desc" inParameters:params];
        [self setValue:details.location.address toKey:@"location_address" inParameters:params];
        if (details.location.latitude && details.location.longitude) {
            NSString *latLong = [NSString stringWithFormat:@"%f,%f", details.location.latitude, details.location.longitude];
            [self setValue:latLong toKey:@"location_latlong" inParameters:params];
        }
    }
    if (details.participants) {
        if (details.participants.emails) {
            [params setObject:[details.participants.emails allObjects] forKey:@"e_inv"];
        }
        if (details.participants.meekanIds) {
            [params setObject:[details.participants.meekanIds allObjects] forKey:@"k_inv"];
        }
        if (details.participants.phoneNumbers) {
            [params setObject:[details.participants.phoneNumbers allObjects] forKey:@"p_inv"];
        }
    }
    endpoint.parameters = params;
    endpoint.path = @"/rest/meetings";
    return endpoint;
}

-(NSArray *)timestampsFromDates:(id<NSFastEnumeration>)timestamps {
    NSMutableArray *options = [NSMutableArray array];
    for (id obj in timestamps) {
        NSString *timestamp;
        if ([obj isKindOfClass:[NSString class]]) {
            timestamp = obj;
        } else if ([obj isKindOfClass:[NSDate class]]) {
            timestamp = [NSString stringWithFormat:@"%.f", [(NSDate *)obj timeIntervalSince1970]];
        } else if ([obj isKindOfClass:[NSNumber class]]) {
            timestamp = [NSString stringWithFormat:@"%ld", (long)[(NSNumber *)obj integerValue]];
        }
        [options addObject:timestamp];
    }
    return options;
}

-(HTTPEndpoint *)updateMeetingUsing:(MeetingDetails *)details {
    return [self endpointForMeetingDetails:details];
}

-(HTTPEndpoint *)deleteMeetingWithId:(NSString *)meetingId {
    HTTPEndpoint *endpoint = nil;
    if (meetingId && [meetingId length]) {
        endpoint = [[HTTPEndpoint alloc]init];
        endpoint.path = [NSString stringWithFormat:@"/rest/meetings/%@", meetingId];
    }
    return endpoint;
}

-(HTTPEndpoint *)listMeetingsSince:(NSDate *)timestamp {
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    endpoint.path = @"/rest/meetings";
    if (timestamp) {
        endpoint.parameters = @{@"last_timestamp" : @([timestamp timeIntervalSince1970])};
    }
    return endpoint;
}

-(HTTPEndpoint *)currentUserDetails {
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    endpoint.path = @"/rest/auth";
    endpoint.parameters = @{};
    return endpoint;
}

-(HTTPEndpoint *)suggestedSlotsUsing:(SlotSuggestionsRequest *)requestDetails {
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    endpoint.path = @"/rest/slots";
    if ([requestDetails.organizerAccountId length] == 0) {
        return nil;
    }
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSMutableArray *ranges = [NSMutableArray array];
    [requestDetails.timeFrameRanges enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj conformsToProtocol:@protocol(TimeRange)]) {
            id<TimeRange> range = obj;
            if ([range isValidTimeRange]) {
                [ranges addObject:[range toTimeRange]];
            }
        }
    }];
    params[@"frames"] = ranges;
    params[@"page"] = requestDetails.page ? @(requestDetails.page) : @(0);
    params[@"organizer_account_id"] = requestDetails.organizerAccountId;
    params[@"duration"] = @(requestDetails.duration);
    if ([requestDetails.inviteesIds count]) {
        params[@"invitees"] = requestDetails.inviteesIds;
    }
    endpoint.parameters = params;
    return endpoint;
}

-(HTTPEndpoint *)freeBusyFor:(NSString *)accountId from:(NSDate *)start until:(NSDate *)end {
    if ([accountId length] == 0 ||
        [start compare:end] == NSOrderedDescending ||
        [end timeIntervalSinceDate:start] > MAX_RANGE_FOR_FREEBUSY) {
        return nil;
    }
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    endpoint.path = [NSString stringWithFormat:@"/rest/accounts/%@/freebusy", accountId];
    endpoint.parameters = @{@"min_date" : @([start timeIntervalSince1970]),
                                @"max_date": @([end timeIntervalSince1970])};
    return endpoint;
}

-(HTTPEndpoint *)voteForMeeting:(NSString *)meetingId asAccount:(NSString *)accountId withVote:(PollVote)vote andPreferredTimes:(NSSet *)preferredTimes {
    if ([meetingId length] && [accountId length] && [self isVote:vote matchesTimes:preferredTimes]) {
        HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
        endpoint.path = [NSString stringWithFormat:@"/rest/meetings/%@/poll/%@", meetingId, accountId];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObject:@(vote) forKey:@"resp_type"];
        if ([preferredTimes count]) {
            params[@"preferred"] = [self timestampsFromDates:preferredTimes];
        }
        endpoint.parameters = params;
        return endpoint;
    } else {
        return nil;
    }
}

- (BOOL)isVote:(PollVote)vote matchesTimes:(NSSet *)preferredTimes {
    switch (vote) {
        case NOT_YET:
            return NO;
        case CUSTOM:
        case MAYBE:
            return preferredTimes != nil;
        case NOT_COMING:
        case WHEN_AVAILABLE:
        case ALWAYS:
            return [preferredTimes count] == 0;
        default:
            return NO;
    }
}

-(void)setValue:(NSString *)value toKey:(NSString *)keyName inParameters:(NSMutableDictionary *)params {
    if (value && [value length] != 0) {
        [params setObject:value forKey:keyName];
    }
}

-(NSDictionary *)parseIdToIdentifiersLookup:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    NSDictionary *data = [self getDataFromResponse:serverResponse orError:error];
    if (!*error && data) {
        return data;
    } else {
        return nil;
    }
}

-(MeetingServerResponse *)parseCreateMeetingResponseFrom:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    return [self parseMeetingChangeResponseFrom:serverResponse andError:error];
}

-(MeetingServerResponse *)parseUpdateMeetingResponseFrom:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    return [self parseMeetingChangeResponseFrom:serverResponse andError:error];
}

- (NSMutableArray *)parseRemoteEventsFrom:(NSDictionary *)data {
    NSMutableArray *remoteEvents = [NSMutableArray array];
    NSDictionary *remoteIds = [data objectForKey:@"remote_id"];
    NSArray *remoteTentativeIds = [data objectForKey:@"remote_tentative_ids"];
    if (remoteIds) {
        [remoteEvents addObject:remoteIds];
    }
    if ([remoteTentativeIds count]) {
        [remoteEvents addObjectsFromArray:remoteTentativeIds];
    }
    return remoteEvents;
}

-(MeetingServerResponse *)parseMeetingChangeResponseFrom:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    NSDictionary *data = [self getDataFromResponse:serverResponse orError:error];
    MeetingServerResponse *response = nil;
    if (!*error && data) {
        NSString *meetingId = [data objectForKey:@"meeting_id"];
        if ([meetingId length]) {
            response = [[MeetingServerResponse alloc]init];
            response.meetingId = meetingId;
            NSMutableArray *remoteEvents;
            remoteEvents = [self parseRemoteEventsFrom:data];
            response.remoteEventIds = remoteEvents;
        } else {
            [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to contain a meeting id" into:error];
        }
    }
    return response;
}

-(MeetingList *)parseMeetingList:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    NSDictionary *data = [self getDataFromResponse:serverResponse orError:error];
    MeetingList *list = [[MeetingList alloc]init];
    [list setHasMore:[[data objectForKey:@"more"] boolValue]];
    NSMutableArray *meetings = [NSMutableArray array];
    for (NSDictionary *meeting in [data objectForKey:@"meetings"]) {
        MeetingFromServer *fromServer = [[MeetingFromServer alloc]init];
        /*
         @property (nonatomic, strong) MeetingDetails *details;
         */
        if ([meeting objectForKey:@"last_update"]) {
            NSTimeInterval lastUpdate = [[meeting objectForKey:@"last_update"] doubleValue];
            fromServer.lastUpdate = [NSDate dateWithTimeIntervalSince1970:lastUpdate];
        }
        fromServer.meetingId = [meeting objectForKey:@"id"];
        fromServer.isDeleted = [[meeting objectForKey:@"is_deleted"] boolValue];
        fromServer.remoteIds = [self parseRemoteEventsFrom:meeting];
        fromServer.votes = [self parseVotesFromMeetingDetails:[meeting objectForKey:@"votes"]];
        fromServer.organizerEmail = [meeting objectForKey:@"organizer_email"];
        fromServer.details = [self parseMeetingDetailsFromMeetingList:meeting];
        [meetings addObject:fromServer];
    }
    [list setMeetings:meetings];
    return list;
}

-(NSSet *)datesFromListOfTimestamps:(NSArray *)timestamps {
    NSMutableSet *times = [NSMutableSet set];
    for (NSNumber *preferredTime in timestamps) {
        [times addObject:[NSDate dateWithTimeIntervalSince1970:[preferredTime doubleValue]]];
    }
    return times;
}

-(MeetingDetails *)parseMeetingDetailsFromMeetingList:(NSDictionary *)data {
    MeetingDetails *details = [[MeetingDetails alloc]init];
    details.title = [data objectForKey:@"name"];
    details.durationInMinutes = [[data objectForKey:@"duration"] integerValue];
    details.accountId = [data objectForKey:@"organizer"];
    details.options = [self datesFromListOfTimestamps:[data objectForKey:@"options"] ];
    details.timeSlotDescription = [data objectForKey:@"time_desc"];
    details.reminderMethod = [data objectForKey:@"reminder_method"];
    details.reminderMinutesBefore = [[data objectForKey:@"reminder_minutes_before"] integerValue];
    details.repeatInterval = [[data objectForKey:@"repeat_interval"] integerValue];
    details.timezone = [data objectForKey:@"timezone"] ? [data objectForKey:@"timezone"] : @"UTC";
    details.participants = [self parseMeetingParticipantsFromArrayOfAccounts:[data objectForKey:@"invitees"]];
    details.location = [self parseMeetingLocationFromMeetingServerResponse:data];
    return details;
}

-(MeetingLocation *)parseMeetingLocationFromMeetingServerResponse:(NSDictionary *)data {
    MeetingLocation *location = [[MeetingLocation alloc]init];
    location.shortDesc = [data objectForKey:@"location_desc"];
    location.address = [data objectForKey:@"location_addresss"];
    if ([data objectForKey:@"location_latlong"]) {
        NSArray *latlong = [[data objectForKey:@"location_latlong"] componentsSeparatedByString:@","];
        if ([latlong count] == 2) {
            location.latitude = [latlong[0] doubleValue];
            location.longitude = [latlong[1] doubleValue];
        }
    }
    return location;
}


-(MeetingParticipants *)parseMeetingParticipantsFromArrayOfAccounts:(NSArray *)accounts {
    MeetingParticipants *participants = [[MeetingParticipants alloc]init];
    participants.meekanIds = [NSSet setWithArray:accounts];
    return participants;
}

-(NSDictionary *)parseVotesFromMeetingDetails:(NSDictionary *)votes {
    NSMutableDictionary *parsedVotes = [NSMutableDictionary dictionary];
    [votes enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSString *voterId = key;
        NSDictionary *serverVote;
        MeetingVote *vote = [[MeetingVote alloc]init];
        vote.accountId = voterId;
        vote.lastUpdate = [NSDate dateWithTimeIntervalSince1970:[[serverVote objectForKey:@"updated"] doubleValue]];
        vote.preferredTimes = [self datesFromListOfTimestamps:[serverVote objectForKey:@"preferred"]];
        vote.email = [serverVote objectForKey:@"email"];
        vote.phone = [serverVote objectForKey:@"phone"];
        vote.vote = [[serverVote objectForKey:@"resp_type"] integerValue];
        
        [parsedVotes setObject:vote forKey:voterId];
    }];
    return parsedVotes;
}

-(ConnectedUser *)parseCurrentUserDetails:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    NSDictionary *data = [self getDataFromResponse:serverResponse orError:error];
    ConnectedUser *user = nil;
    if (!*error && data) {
        user = [[ConnectedUser alloc]init];
        user.name = [data objectForKey:@"name"];
        user.userId = [data objectForKey:@"user_id"];
        user.primaryEmail = [data objectForKey:@"primary_email"];
        NSMutableArray *parsedAccounts = [NSMutableArray array];
        for (NSDictionary *responseAccount in [data objectForKey:@"accounts"]) {
            ConnectedAccount *account = [[ConnectedAccount alloc]init];
            account.meekanId = [responseAccount objectForKey:@"id"];
            account.identifier = [responseAccount objectForKey:@"identifier"];
            account.name = [responseAccount objectForKey:@"name"];
            account.accountType = [responseAccount objectForKey:@"type"];
            [parsedAccounts addObject:account];
        }
        user.accounts = parsedAccounts;
    }
    
    return user;
}

-(NSArray *)parseSuggestedSlotList:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    NSArray *data = [self getDataArrayFromResponse:serverResponse optional:YES orError:error];
    NSMutableArray *suggestions = [[NSMutableArray alloc]init];
    if (!*error && data) {
        for (NSDictionary *suggestionFromServer in data) {
            SlotSuggestion *suggestion = [[SlotSuggestion alloc]init];
            NSTimeInterval start = [[suggestionFromServer objectForKey:@"start"] doubleValue];
            suggestion.start = [NSDate dateWithTimeIntervalSince1970:start];
            suggestion.busyIds = [NSSet setWithArray:[suggestionFromServer objectForKey:@"not_available"]];
            suggestion.rank = [[suggestionFromServer objectForKey:@"rank"] integerValue];
            [suggestions addObject:suggestion];
        }
    }
    
    return suggestions;
}

-(NSArray *)parseFreeBusy:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    NSArray *data = [self getDataArrayFromResponse:serverResponse optional:YES orError:error];
    NSMutableArray *freeBusy = [[NSMutableArray alloc]init];
    if (!*error && data) {
        for (NSDictionary *freeBusyPeriod in data) {
            NSTimeInterval start = [[freeBusyPeriod objectForKey:kMKNTimeRangeStartKey] doubleValue];
            NSTimeInterval end = [[freeBusyPeriod objectForKey:kMKNTimeRangeEndKey] doubleValue];
            [freeBusy addObject:@{kMKNTimeRangeStartKey: [NSDate dateWithTimeIntervalSince1970:start],
                                  kMKNTimeRangeEndKey: [NSDate dateWithTimeIntervalSince1970:end]}];
        }
    }
    
    return freeBusy;
}


-(NSDictionary *)getDataFromResponse:(id)serverResponse orError:(NSError *__autoreleasing *)error {
    return [self getDataDictionaryFromResponse:serverResponse optional:YES orError:error];
}

-(NSDictionary *)getDataDictionaryFromResponse:(id)serverResponse optional:(BOOL)isOptional orError:(NSError *__autoreleasing *)error {
    if ([serverResponse isKindOfClass:[NSDictionary class]]) {
        NSDictionary *base = serverResponse;
        if ([base objectForKey:@"data"]) {
            NSDictionary *data = [base objectForKey:@"data"];
            return data;
        } else {
            if (isOptional) {
                return @{};
            } else {
                [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to include 'data'" into:error];
            }
        }
    } else {
        [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to be a dictionary" into:error];
    }
    
    return nil;
}

-(NSArray *)getDataArrayFromResponse:(id)serverResponse  optional:(BOOL)isOptional orError:(NSError *__autoreleasing *)error{
    if ([serverResponse isKindOfClass:[NSDictionary class]]) {
        NSDictionary *base = serverResponse;
        if ([base objectForKey:@"data"]) {
            NSArray *data = [base objectForKey:@"data"];
            return data;
        } else {
            if (isOptional) {
                return @[];
            } else {
                [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to include 'data'" into:error];
            }
        }
    } else {
        [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to be a array" into:error];
    }
    
    return nil;
}

-(void)insertErrorCode:(NSInteger)errorCode andMessage:(NSString *)message into:(NSError *__autoreleasing *)error {
    if (error) {
        *error = [NSError errorWithDomain:kMKNClientErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey: message}];
    }
}

@end
