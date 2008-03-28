//
//  TDMovieAttributesController.h
//  Vidnik
//
//  Created by david on 2/21/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>
#import "TDConstants.h"

@class TDModelMovie;

@interface TDMovieAttributesController : NSResponder {
  IBOutlet  NSTextField   *mTitle;
  IBOutlet  NSTextField   *mKeywords;
  IBOutlet  NSTextView    *mDescription;
  IBOutlet  NSPopUpButton *mCategory;
  IBOutlet  NSTextField   *mStatus;
  TDModelMovie *mMovie;
  IBOutlet  id  mDelegate;
}
// ### Atrributes
- (NSString *)title;
- (NSArray *)keywords;
- (NSString *)details;
- (NSString *)category;
- (id)delegate;

- (NSString *)status;
- (void)setStatus:(NSString *)status;
- (void)setState:(ModelMovieState)movieState;


- (void)setModelMovie:(TDModelMovie *)modelMovie;

- (IBAction)categoryChanged:(id)sender;
@end
