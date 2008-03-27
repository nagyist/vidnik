//
//  TDModelDate.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. All rights reserved.
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
