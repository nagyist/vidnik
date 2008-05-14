//
//  AlphaNumFormatter.m
//  Vidnik
//
//  Created by David Oster on 4/25/08.
//  Copyright 2008 Google Inc. All rights reserved.
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

#import "AlphaNumFormatter.h"
#import "TDConfiguration.h"
#import "TDConstants.h"


@implementation AlphaNumFormatter

- (NSString *)stringForObjectValue:(id)obj {
  return ([obj respondsToSelector:@selector(characterAtIndex:)] ? obj : @"");
}

- (BOOL)getObjectValue:(id *)obj 
             forString:(NSString *)string
      errorDescription:(NSString **)error {
  if (error) {
    *error = nil;
  }
  if (obj) {
    *obj = [[string copy] autorelease];
  }
  return nil != string;
}

- (NSAttributedString *)attributedStringForObjectValue:(id)obj 
                                 withDefaultAttributes:(NSDictionary *)attrs {
  return [[[NSAttributedString alloc] initWithString:obj attributes:attrs] autorelease];
}



- (BOOL)isPartialStringValid:(NSString *)partialString 
            newEditingString:(NSString **)newString
            errorDescription:(NSString **)error {
  BOOL isGood = YES;
  if (0 < [partialString length] && ! [TDConfig() isAnyUserNameAllowed]) {
    NSScanner *scanner = [NSScanner scannerWithString:partialString];
    static NSMutableCharacterSet *legalset = nil;
    if (nil == legalset) {
      legalset = [[NSCharacterSet characterSetWithRange:NSMakeRange('a', 26)] mutableCopy];
      [legalset addCharactersInRange:NSMakeRange('A', 26)];
      [legalset addCharactersInRange:NSMakeRange('0', 10)];
    }
    [NSCharacterSet alphanumericCharacterSet];
    NSString *legalString = nil;
    isGood = ([scanner scanCharactersFromSet:legalset intoString:&legalString] &&
            [partialString isEqual:legalString]);
    if ( ! isGood) {
      if (error) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"BadUsernameErr", @""), NSLocalizedDescriptionKey,
          nil];
        *error = [NSError errorWithDomain:kTDAppDomain
                                     code:kBadUsernameErr
                                 userInfo:info];
      }
    }
  }     
  if ( ! isGood && newString) {
      *newString = partialString;
  }
  return isGood;
}

@end
