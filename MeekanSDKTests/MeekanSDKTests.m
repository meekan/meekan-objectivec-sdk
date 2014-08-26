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

@end

@implementation MeekanSDKTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample
{
        MeekanSDK *sdk = [MeekanSDK sharedInstanceWithApiKey:@"AnyKey"];
//    NewTestClass *cl = [[NewTestClass alloc]init];
//    MeetingDetails *details = [[MeetingDetails alloc]init];
//    details.accountId = @"4785074604081152";
//    details.title = @"Test";
//    details.durationInMinutes = 10;
//    
    
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
