//
//  ApiV1Adapter.m
//  MeekanSDK
//
//  Created by Eyal Yavor on 24/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import "MKNApiAdapter.h"
#import "MKNParameters.h"

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
                err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:errorCode userInfo:@{NSLocalizedDescriptionKey: errorMessage ? errorMessage : @"Server Error"}];
            }
        } else {
            err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:UNEXPECTED_RESPONSE_FORMAT
                                  userInfo:@{NSLocalizedDescriptionKey:
                                                 NSLocalizedString(@"Expected Body to be a dictionary", nil)}];
        }
    } else {
        err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:MISSING_RESPONSE_BODY
                                       userInfo:@{NSLocalizedDescriptionKey:
                                                      NSLocalizedString(@"Expected Response body, received empty", nil)}];
    }
    return err;
}

-(HTTPEndpoint *)createMeetingUsing:(MeetingDetails *)details {
    return [self endpointForMeetingDetails:details];
}

-(HTTPEndpoint *)endpointForMeetingDetails:(MeetingDetails *)details {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    
    if ([details.accountId length] == 0 && details.durationInMinutes == 0) {
        return nil;
    }
    //
    //    @property (nonatomic, strong) MeetingParticipants *participants;
    //
    [self setValue:details.accountId toKey:@"account_id" inParameters:params];
    [self setValue:details.title toKey:@"title" inParameters:params];
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
        NSMutableArray *options = [NSMutableArray arrayWithCapacity:[details.options count]];
        [details.options enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            NSString *timestamp;
            if ([obj isKindOfClass:[NSString class]]) {
                timestamp = obj;
            } else if ([obj isKindOfClass:[NSDate class]]) {
                timestamp = [NSString stringWithFormat:@"%.f", [(NSDate *)obj timeIntervalSince1970]];
            } else if ([obj isKindOfClass:[NSNumber class]]) {
                timestamp = [NSString stringWithFormat:@"%ld", (long)[(NSNumber *)obj integerValue]];
            }
            [options addObject:timestamp];
        }];
        [params setObject:options forKey:@"opt"];
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

-(HTTPEndpoint *)currentUserDetails {
    HTTPEndpoint *endpoint = [[HTTPEndpoint alloc]init];
    endpoint.path = @"/rest/auth";
    endpoint.parameters = @{};
    return endpoint;
}

-(void)setValue:(NSString *)value toKey:(NSString *)keyName inParameters:(NSMutableDictionary *)params {
    if (value && [value length] != 0) {
        [params setObject:value forKey:keyName];
    }
}

-(MeetingServerResponse *)parseCreateMeetingResponseFrom:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    return [self parseMeetingChangeResponseFrom:serverResponse andError:error];
}

-(MeetingServerResponse *)parseUpdateMeetingResponseFrom:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    return [self parseMeetingChangeResponseFrom:serverResponse andError:error];
}

-(MeetingServerResponse *)parseMeetingChangeResponseFrom:(id)serverResponse andError:(NSError *__autoreleasing *)error {
    NSDictionary *data = [self getDataFromResponse:serverResponse orError:error];
    MeetingServerResponse *response = nil;
    if (!*error && data) {
        NSString *meetingId = [data objectForKey:@"meeting_id"];
        NSDictionary *remoteIds = [data objectForKey:@"remote_id"];
        NSArray *remoteTentativeIds = [data objectForKey:@"remote_tentative_ids"];
        if ([meetingId length]) {
            response = [[MeetingServerResponse alloc]init];
            response.meetingId = meetingId;
            NSMutableArray *remoteEvents = [NSMutableArray array];
            if (remoteIds) {
                [remoteEvents addObject:remoteIds];
            }
            if ([remoteTentativeIds count]) {
                [remoteEvents addObjectsFromArray:remoteTentativeIds];
            }
            response.remoteEventIds = remoteEvents;
        } else {
            [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to contain a meeting id" into:error];
        }
    }
    return response;
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


-(NSDictionary *)getDataFromResponse:(id)serverResponse orError:(NSError *__autoreleasing *)error {
    if ([serverResponse isKindOfClass:[NSDictionary class]]) {
        NSDictionary *base = serverResponse;
        if ([base objectForKey:@"data"]) {
            NSDictionary *data = [base objectForKey:@"data"];
            return data;
        } else {
            [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to include 'data'" into:error];
        }
    } else {
        [self insertErrorCode:UNEXPECTED_RESPONSE_FORMAT andMessage:@"Expected response to be a dictionary" into:error];
    }
    
    return nil;
}

-(void)insertErrorCode:(NSInteger)errorCode andMessage:(NSString *)message into:(NSError *__autoreleasing *)error {
    if (error) {
        *error = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:errorCode userInfo:@{NSLocalizedDescriptionKey: message}];
    }
}

@end
