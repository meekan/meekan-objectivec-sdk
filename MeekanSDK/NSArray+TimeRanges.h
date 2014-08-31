//
//  NSArray+TimeRanges.h
//  TestMeekanSDK
//
//  Created by Eyal Yavor on 31/8/14.
//  Copyright (c) 2014 Meekan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (TimeRanges)
-(BOOL)isValidTimeRange;
-(NSString *)toTimeRange;
@end
//
//@interface NSString (TimeRanges) <TimeRange>
//-(BOOL)isValidTimeRange;
//-(NSString *)toTimeRange;
//@end
//
//@interface NSDictionary (TimeRanges) <TimeRange>
//-(BOOL)isValidTimeRange;
//-(NSString *)toTimeRange;
//@end
