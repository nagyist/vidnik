//
//  TDModelDate.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDModelDate.h"


@implementation TDModelDate
- (NSString *)asSimpleString {
  return [NSString stringWithFormat:@"%04d-%02d-%02d %02d-%02d-%02d",
    [self yearOfCommonEra],
    [self monthOfYear],
    [self dayOfMonth],
    [self hourOfDay],
    [self minuteOfHour],
    [self secondOfMinute]];
}

@end
