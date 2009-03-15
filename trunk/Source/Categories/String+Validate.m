//
//  String+Validate.m
//  Vidnik
//
//  Created by David Oster on 3/14/09.
//
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

#import "String+Validate.h"


@implementation NSString(Validate)

- (NSString *)atMostCharacters:(int)maxCharacters {
  if (0 <= maxCharacters && maxCharacters < [self length]) {
    return [self substringToIndex:maxCharacters];
  }
  return self;
}

// Inefficient but robust: remove characters from the end of the string until
// the UTF8 version of the string fits within the constraint.
- (NSString *)atMostBytes:(int)maxBytes {
  if (0 <= maxBytes) {
    for (;[self length];) {
      NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
      if ([data length] < maxBytes) {
        return self;
      }
      self = [self substringToIndex:[self length]-1];
    }
  }
  return self;
}

- (NSString *)stringByRemovingCharactersFromSet:(NSCharacterSet *)stripSet {
  NSRange badRange = [self rangeOfCharacterFromSet:stripSet];
  if (NSNotFound != badRange.location) {
    NSMutableString *s = [NSMutableString string];
    NSRange remaining = NSMakeRange(0, [self length]);
    while (0 < remaining.length && NSNotFound != badRange.location) {
      NSRange newPrefixRange =
        NSMakeRange(remaining.location, badRange.location - remaining.location);
      NSString *segment = [self substringWithRange:newPrefixRange];
      [s appendString:segment];
      remaining.location += [segment length] + badRange.length;
      remaining.length -= [segment length] + badRange.length;
      badRange = [self rangeOfCharacterFromSet:stripSet options:0 range:remaining];
    }
    [s appendString:[self substringWithRange:remaining]];
    return s;
  }
  return self;
}

@end
