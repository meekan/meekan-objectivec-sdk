//
//  MeekanSDK.m
//  MeekanSDK
//
//  Created by Eyal Yavor on 24/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import "MeekanSDK.h"
#import "AFNetworking.h"

@interface MeekanSDK ()
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, strong) AFHTTPSessionManager *manager;
@end

@implementation MeekanSDK

static NSString *API_URL = @"http://localhost:8080";

static MeekanSDK *sharedInstance = nil;

+(MeekanSDK *)sharedInstance {
    assert(sharedInstance != nil);
    return sharedInstance;
}

+(MeekanSDK *)sharedInstanceWithApiKey:(NSString *)apiKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super alloc] initWithApiKey:apiKey];
    });
    return sharedInstance;
}

-(id)initWithApiKey:(NSString *)apiKey {
    if ([apiKey length] == 0) {
        NSLog(@"%@: API Key is Empty", self);
    }
    if (self = [self init]) {
        self.apiKey = apiKey;
        self.apiAdapter = [[ApiV1Adapter alloc]init];
        self.manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:API_URL]];
        self.manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        [self.manager.requestSerializer setValue:[NSString stringWithFormat:@"Meekan %@", self.apiKey] forHTTPHeaderField:@"Authorization"];
        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];

    }
    
    return self;
}

-(void)createMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self.apiAdapter respondsToSelector:@selector(createMeetingUsing:)]) {
        HTTPEndpoint *endpoint = [self.apiAdapter createMeetingUsing:meeting];
        if (endpoint) {
            [self.manager POST:endpoint.path parameters:endpoint.parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
                if (!errorInRespone) {
                    MeetingServerResponse *response = [self.apiAdapter parseCreateMeetingResponseFrom:responseObject andError:&errorInRespone];
                    if (!errorInRespone) {
                        successCallback(response);
                    } else {
                        errorCallback(errorInRespone);
                    }
                } else {
                    errorCallback(errorInRespone);
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                errorCallback(error);
            }];
        } else {
            NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:INVALID_PARAMETERS
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for Create Meeting %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Create Meeting is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

-(void)updateMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self.apiAdapter respondsToSelector:@selector(updateMeetingUsing:)]) {
        HTTPEndpoint *endpoint = [self.apiAdapter updateMeetingUsing:meeting];
        if (endpoint) {
            [self.manager POST:endpoint.path parameters:endpoint.parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
                if (!errorInRespone) {
                    MeetingServerResponse *response = [self.apiAdapter parseUpdateMeetingResponseFrom:responseObject andError:&errorInRespone];
                    if (!errorInRespone) {
                        successCallback(response);
                    } else {
                        errorCallback(errorInRespone);
                    }
                } else {
                    errorCallback(errorInRespone);
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                errorCallback(error);
            }];
        } else {
            NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:INVALID_PARAMETERS
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for Update Meeting %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Update Meeting is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

-(void)deleteMeeting:(NSString *)meetingId onSuccess:(MeetingDeleteSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self.apiAdapter respondsToSelector:@selector(updateMeetingUsing:)]) {
        HTTPEndpoint *endpoint = [self.apiAdapter deleteMeetingWithId:meetingId];
        if (endpoint) {
            [self.manager DELETE:endpoint.path parameters:endpoint.parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
                if (!errorInRespone) {
                    successCallback(meetingId);
                } else {
                    errorCallback(errorInRespone);
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                errorCallback(error);
            }];
        } else {
            NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:INVALID_PARAMETERS
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for Update Meeting %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Update Meeting is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

@end
