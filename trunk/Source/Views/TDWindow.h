//
//  TDWindow.h
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

#import <Cocoa/Cocoa.h>

// title bar shows document is associated with an account
@interface TDWindow : NSWindow {
  @private
    NSString *mOuterTitle;
    NSString *mRepresentedFile;
}
- (NSString *)actualTitle;

// overrides
- (NSString *)title;
- (void)setTitle:(NSString *)aString;

@end

@interface NSObject(TDWindowDelegate)
- (NSString *)account;
@end
