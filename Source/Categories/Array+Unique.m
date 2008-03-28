//
//  Array+Unique.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/26/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "Array+Unique.h"


@implementation NSArray(Unique)
- (NSArray *)unique {
  NSMutableSet *set = [NSMutableSet set];
  int i, iCount = [self count];
  for (i = 0; i < iCount; ++i) {
    NSString *s = [self objectAtIndex:i];
    [set addObject:[s lowercaseString]];
  }
  NSMutableArray *val = [NSMutableArray array];
  for (i = 0; i < iCount; ++i) {
    NSString *s = [self objectAtIndex:i];
    NSString *sLower = [s lowercaseString];
    if ([set containsObject:sLower]) {
      [set removeObject:sLower];
      [val addObject:s];
    }
  }
  return val;
}

@end
