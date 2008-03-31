//
//  StringFormat.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/20/08.
//  Copyright 2008 Google Inc. 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.

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

