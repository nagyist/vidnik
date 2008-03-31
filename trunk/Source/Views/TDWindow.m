//
//  TDWindow.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/29/08.
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

#import "TDWindow.h"
#import "TDPlaylistController.h"

@implementation TDWindow
- (void)dealloc {
  [mOuterTitle release];
  [mRepresentedFile release];
  [super dealloc];
}

- (NSString *)actualTitle {
  NSString *accountName = [[self delegate] account];
  if (0 == [accountName length]) {
    accountName = NSLocalizedString(@"account not set", @"Window Title");
  }
  return [NSString stringWithFormat:@"%@ : %@", mOuterTitle ? mOuterTitle : @"", accountName]; 
}

- (NSString *)title {
  return mOuterTitle;
}


- (void)setTitle:(NSString *)aString {
  [mOuterTitle autorelease];
  mOuterTitle = [aString copy];
  [super setTitle:[self actualTitle]];
}

@end
