//
//  TDWindow.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/29/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
