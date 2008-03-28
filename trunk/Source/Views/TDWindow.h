//
//  TDWindow.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/29/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
