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

- (MKNGoogleLoginViewController *)connectWithGoogleWithCompletionHandler:(MKNGoogleLoginViewControllerCompletionHandler)completion {    MKNGoogleLoginViewController *controller = [[MKNGoogleLoginViewController alloc]initWithNibName:@"MKNGoogleLoginViewController" bundle:[NSBundle mainBundle]];
    controller.adapter = self.apiAdapter;
    controller.completion = completion;
    return controller;
}

- (void)connectWithExchangeUser:(NSString *)username withPassword:(NSString *)password withEmail:(NSString *)email withServerUrl:(NSString *)url andDomain:(NSString *)domain onSuccess:(ConnectedUserSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self isAllNotEmpty:@[username, password, email, url, domain]]) {
        NSError *argumentsError;
        NSData *jsonArgs = [self jsonOf:@{@"username":username, @"password":password, @"email": email,
                                          @"url":url, @"domain":domain} error:&argumentsError];
        if (!argumentsError && jsonArgs) {
            NSString *json = [[NSString alloc]initWithData:jsonArgs encoding:NSUTF8StringEncoding];
            NSDictionary *params = @{@"state": json};
            [self.manager GET:@"/social_login/exchange/complete" parameters:params success:^(NSURLSessionDataTask *task, id responseObject) {
                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
                if (!errorInRespone) {
                    [self extractConnectedUser:responseObject error:&errorInRespone errorCallback:errorCallback successCallback:successCallback];
                } else {
                    errorCallback(errorInRespone);
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                errorCallback(error);
            }];
        } else {
            errorCallback(argumentsError);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:INVALID_PARAMETERS
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for Exchange Connection %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

- (NSData *)jsonOf:(NSDictionary *)params error:(NSError *__autoreleasing *)err {
    NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:err];
    return data;
}

-(BOOL)isAllNotEmpty:(NSArray *)params {
    BOOL allOk = YES;
    for (NSString *param in params) {
        allOk &= [param length] != 0;
    }
    return allOk;
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
    if ([self.apiAdapter respondsToSelector:@selector(deleteMeetingWithId:)]) {
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
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for Delete Meeting %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Delete Meeting is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

-(void)listMeetingsForAccountSince:(NSDate *)timestamp onSuccess:(MeetingListSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self.apiAdapter respondsToSelector:@selector(listMeetingsSince:)]) {
        HTTPEndpoint *endpoint = [self.apiAdapter listMeetingsSince:timestamp];
        if (endpoint) {
            [self.manager GET:endpoint.path parameters:endpoint.parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
                if (!errorInRespone) {
                    MeetingList *list = [self.apiAdapter parseMeetingList:responseObject andError:&errorInRespone];
                    if (!errorInRespone) {
                        successCallback(list);
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
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for List Meetings %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"List Meetings is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

-(void)suggestedSlots:(SlotSuggestionsRequest *)request onSuccess:(SlotListSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self.apiAdapter respondsToSelector:@selector(suggestedSlotsUsing:)]) {
        HTTPEndpoint *endpoint = [self.apiAdapter suggestedSlotsUsing:request];
        if (endpoint) {
            [self.manager GET:endpoint.path parameters:endpoint.parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
                if (!errorInRespone) {
                    NSArray *list = [self.apiAdapter parseSuggestedSlotList:responseObject andError:&errorInRespone];
                    if (!errorInRespone) {
                        successCallback(list);
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
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for Suggested Slots %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Suggested Slots is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

- (void)extractConnectedUser:(id)responseObject error:(NSError **)errorInRespone_p errorCallback:(MeekanResponseError)errorCallback successCallback:(ConnectedUserSuccess)successCallback {
    ConnectedUser *user = [self.apiAdapter parseCurrentUserDetails:responseObject andError:&(*errorInRespone_p)];
    if (!(*errorInRespone_p)) {
        successCallback(user);
    } else {
        errorCallback(*errorInRespone_p);
    }
}

- (void)connectedUserDetailsWithSuccess:(ConnectedUserSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self.apiAdapter respondsToSelector:@selector(currentUserDetails)]) {
        HTTPEndpoint *endpoint = [self.apiAdapter currentUserDetails];
        if (endpoint) {
            [self.manager GET:endpoint.path parameters:endpoint.parameters success:^(NSURLSessionDataTask *task, id responseObject) {
                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
                if (!errorInRespone) {
                    [self extractConnectedUser:responseObject error:&errorInRespone errorCallback:errorCallback successCallback:successCallback];
                } else {
                    errorCallback(errorInRespone);
                }
            } failure:^(NSURLSessionDataTask *task, NSError *error) {
                errorCallback(error);
            }];
        } else {
            NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:INVALID_PARAMETERS
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Please review required parameters for Current User %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Current User is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

@end
