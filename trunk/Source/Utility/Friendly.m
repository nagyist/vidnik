//
//  Friendly.m
//  Progress
//
//  Created by David Phillip Oster on 3/12/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//
#import "Friendly.h"

NSString *FriendlyStringFromTime(NSTimeInterval time) {
  if (3600*24*30*2. < time) {
    return [NSString stringWithFormat:@"about %d months", (int) (time / (3600*24*30.))];
  } else if (3600*24*2. < time) {
    return [NSString stringWithFormat:@"about %d days", (int) (time / (3600*24.))];
  } else if (3600*2. < time) {
    return [NSString stringWithFormat:@"about %d hours", (int) (time / 3600.)];
  } else if (60*2. < time) {
    return [NSString stringWithFormat:@"about %d minutes", (int) (time / 60.)];
  } else if (50. < time) {
    return @"about a minute";
  } else if (20. < time) {
    return @"about 30 seconds";
  } else if (0.5 < time && time <= 2.) {
    return @"about a second";
  } else if (2. < time) {
    return [NSString stringWithFormat:@"about %d seconds", (int) time];
  } else {
    return @"";
  }
}

NSString *FriendlyBytes(SInt64 fileSize) {
  if (900000000000000000LL < fileSize) { // E
   return [NSString stringWithFormat:@"%.2fE", fileSize / 1.0e18];
  } else if (900000000000000LL < fileSize) { // P
   return [NSString stringWithFormat:@"%.2fP", fileSize / 1.0e15];
  } else if (900000000000LL < fileSize) { // T
   return [NSString stringWithFormat:@"%.2fT", fileSize / 1.0e12];
  } else if (900000000LL < fileSize) { // G
    return [NSString stringWithFormat:@"%.1fG", fileSize / 1.0e9];
  } else if (900000 < fileSize) {  // M
    return [NSString stringWithFormat:@"%.0fM", fileSize / 1.0e6];
  } else if (1000 < fileSize) { // K
    return [NSString stringWithFormat:@"%.0fK", fileSize / 1.0e3];
  } else { // B
    return [NSString stringWithFormat:@"%dB", (int) fileSize];
  }
}

