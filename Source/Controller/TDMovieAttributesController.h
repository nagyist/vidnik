//
//  TDMovieAttributesController.h
//  Vidnik
//
//  Created by david on 2/21/08.
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
#import "TDConstants.h"

@class TDModelMovie;

@interface TDMovieAttributesController : NSResponder {
  IBOutlet  NSTextField   *mTitle;
  IBOutlet  NSTextField   *mTitleLegend;
  IBOutlet  NSTextField   *mKeywords;
  IBOutlet  NSTextField   *mKeywordsLegend;
  IBOutlet  NSTextView    *mDescription;
  IBOutlet  NSTextField   *mDescriptionLegend;
  IBOutlet  NSPopUpButton *mCategory;
  IBOutlet  NSTextField   *mCategoryLegend;
  IBOutlet  NSTextField   *mStatus;
  TDModelMovie *mMovie;
  IBOutlet  id  mDelegate;
}
// ### Atrributes
- (NSString *)title;
- (NSArray *)keywords;  // of NSString
- (NSString *)details;
- (NSString *)category;
- (id)delegate;

- (NSString *)status;
- (void)setStatus:(NSString *)status;
- (void)setState:(ModelMovieState)movieState;


- (void)setModelMovie:(TDModelMovie *)modelMovie;

- (IBAction)categoryChanged:(id)sender;
@end

@interface NSObject (TDMovieAttributesControllerDelegate)
- (NSString *)account;
@end
