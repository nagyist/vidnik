//
//  TDSplitController.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/6/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDSplitController.h"

enum {
  kSpltterWidth = 8,
  kLeftMinWidth = 178,
  kRightMinWidth = 544 - (kLeftMinWidth + kSpltterWidth),
};

@implementation TDSplitController

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedCoord ofSubviewAt:(int)offset {
  return kLeftMinWidth;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedCoord ofSubviewAt:(int)offset {
  return [sender frame].size.width - kSpltterWidth - kRightMinWidth;
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
  return NO;
}

@end
