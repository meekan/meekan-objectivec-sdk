//
//  NSArray+TimeRanges.h
//  TestMeekanSDK
//
//  Created by Eyal Yavor on 31/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TimeRange <NSObject>
@required
-(BOOL)isValidTimeRange;
-(NSString *)toTimeRange;
@end

@interface NSArray (TimeRanges) <TimeRange>
@end

@interface NSString (TimeRanges) <TimeRange>
@end

@interface NSDictionary (TimeRanges) <TimeRange>
@end
