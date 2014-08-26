//
//  MeekanSDK.m
//  MeekanSDK
//
//  Created by Eyal Yavor on 24/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import "MeekanSDK.h"
#import "AFNetworking/AFNetworking.h"

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
        NSURL *url = [NSURL URLWithString:API_URL];
//        self.manager = [[AFHTTPSessionManager alloc]initWithBaseURL:[NSURL URLWithString:API_URL]];
//        self.manager.requestSerializer = [AFJSONRequestSerializer serializer];
//        self.manager.responseSerializer = [AFJSONResponseSerializer serializer];
    }
    
    return self;
}

-(void)createMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)successCallback onError:(MeekanResponseError)errorCallback {
    if ([self.apiAdapter respondsToSelector:@selector(createMeetingUsing:)]) {
        HTTPEndpoint *endpoint = [self.apiAdapter createMeetingUsing:meeting];
        if (endpoint) {
//            [self.manager GET:endpoint.path parameters:endpoint.parameters success:^(NSURLSessionDataTask *task, id responseObject) {
//                NSError *errorInRespone = [self.apiAdapter checkIfError:responseObject];
//                if (!errorInRespone) {
//                    
//                } else {
//                    errorCallback(errorInRespone);
//                }
//                if (responseObject != nil && [responseObject isKindOfClass:[NSDictionary class]]) {
//                    
//                    // Find error code and message
//                    
//                } else {
//
//                }
//            } failure:^(NSURLSessionDataTask *task, NSError *error) {
//                errorCallback(error);
//            }];
        } else {
            NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:INVALID_PARAMETERS
                                           userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Create Meeting is not supported in adapter %@",self.apiAdapter]}];
            errorCallback(err);
        }
    } else {
        NSError *err = [NSError errorWithDomain:MEEKAN_CLIENT_ERROR_DOMAIN code:NOT_IMPLEMENTED_IN_THIS_SDK
                                       userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Create Meeting is not supported in adapter %@",self.apiAdapter]}];
        errorCallback(err);
    }
}

-(void)updateMeeting:(MeetingDetails *)meeting onSuccess:(MeetingResponseSuccess)success onError:(MeekanResponseError)error {
    
}

@end
