//
//  TDWindow.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/29/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

// Trampoline actions from menu bar to this to Document.
// (Just setting the delegate did not do the trick.)
@interface TDWindow : NSWindow {
  @private
    NSString *mOuterTitle;
    NSString *mRepresentedFile;
}
- (IBAction)fetchCredentials:(id)sender;
- (IBAction)forgetCredentials:(id)sender;
- (NSString *)actualTitle;

// overrides
- (NSString *)title;
- (void)setTitle:(NSString *)aString;

@end

@interface NSObject(TDWindowDelegate)
- (NSString *)account;
@end
