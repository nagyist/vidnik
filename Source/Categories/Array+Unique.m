//
//  Array+Unique.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/26/08.
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
