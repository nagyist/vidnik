//
//  AlphaNumFormatter.h
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

#import <Cocoa/Cocoa.h>

// Used for the Username field in the sign in dialog box. Only allows
// YouTube legal characters, unless:
// if (isAnyUserNameAllowed) allow anything.
// isAnyUserNameAllowed is a Preference file preference
//
@interface AlphaNumFormatter : NSFormatter

- (NSString *)stringForObjectValue:(id)obj;

- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error;

- (BOOL)isPartialStringValid:(NSString *)partialString 
            newEditingString:(NSString **)newString
            errorDescription:(NSString **)error;
@end
