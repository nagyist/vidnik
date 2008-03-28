//
//  ProgressIndicatorCell.h
//  Progress
//
//  Created by David Phillip Oster on 3/12/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

// the pure progress meter portion of the cell.
// doesn't handle indeterminate, for now.
@interface ProgressIndicatorCell : NSLevelIndicatorCell {
  BOOL mIsIndeterminate;
}
- (BOOL)isIndeterminate;
- (void)setIndeterminate:(BOOL)isIndeterminate;
@end
