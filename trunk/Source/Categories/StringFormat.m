//
//  StringFormat.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/20/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "StringFormat.h"
#import "Friendly.h"

@implementation NSString(FormatMethods)

+ (NSString *)stringFromFileSize:(UInt64) fileSize {
  return FriendlyBytes(fileSize);
}

+ (NSString *)stringFromTime:(NSTimeInterval) duration {
  NSAssert(0. <= duration, @"");
  int hours = duration / (60.*60.);
  duration -= hours * (60.*60.);
  int minutes = duration / 60.;
  duration -= minutes * 60.;
  return [NSString stringWithFormat:@"%02d:%02d:%04.1f", hours, minutes, duration];
}

+ (NSString *)stringFromTimeShort:(NSTimeInterval) duration {
  int minutes = duration / 60.;
  duration -= minutes * 60.;
  return [NSString stringWithFormat:@"%02d:%04.1f", minutes, duration];
}

@end

