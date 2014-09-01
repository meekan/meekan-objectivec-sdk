//
//  NSArray+TimeRanges.m
//  TestMeekanSDK
//
//  Created by Eyal Yavor on 31/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import "NSObject+TimeRanges.h"

@implementation NSArray (TimeRanges)

-(BOOL)isValidTimeRange {
    return [self count] == 2 &&
            [self[0] isKindOfClass:[NSDate class]] &&
            [self[1] isKindOfClass:[NSDate class]];
}

-(NSString *)toTimeRange {
    return [NSString stringWithFormat:@"%d:%d", (int)[self[0] timeIntervalSince1970], (int)[self[1] timeIntervalSince1970]];
}

@end

@implementation NSDictionary (TimeRanges)

-(BOOL)isValidTimeRange {
    return
        [self objectForKey:@"start"] && [self[@"start"] isKindOfClass:[NSDate class]] &&
        [self objectForKey:@"end"] && [self[@"end"] isKindOfClass:[NSDate class]];
}

-(NSString *)toTimeRange {
    return [NSString stringWithFormat:@"%d:%d", (int)[self[@"start"] timeIntervalSince1970], (int)[self[@"end"] timeIntervalSince1970]];
}

@end

@implementation NSString (TimeRanges)

-(BOOL)isValidTimeRange {
    NSArray *parts = ([self componentsSeparatedByString:@":"]);
    return [parts count] == 2 &&
        [parts[0] integerValue] &&
        [parts[1] integerValue];
}

-(NSString *)toTimeRange {
    return self;
}

@end
