//
//  ProgressIndicatorCell.m
//  Progress
//
//  Created by David Phillip Oster on 3/12/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "ProgressIndicatorCell.h"
@implementation ProgressIndicatorCell

- (id)init {
  self = [super initWithLevelIndicatorStyle:NSContinuousCapacityLevelIndicatorStyle];
  return self;
}


- (BOOL)isIndeterminate {
  return mIsIndeterminate;
}

- (void)setIndeterminate:(BOOL)isIndeterminate {
  if (mIsIndeterminate != isIndeterminate) {
    mIsIndeterminate = isIndeterminate;
    [[self controlView] setNeedsDisplay:YES];
  }
}

#if 0
- (void)drawNotReadyWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [[NSColor colorWithCalibratedRed:(239/255.) green:(141/255.) blue:(148/255.) alpha:1.] set];
  [NSBezierPath fillRect:cellFrame];
  [[NSColor colorWithCalibratedRed:(191/255.) green:(11/255.) blue:(24/255.) alpha:1.] set];
  [NSBezierPath strokeRect:cellFrame];
}
#endif

- (void)drawIndeterminateWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  [[NSColor colorWithCalibratedRed:(194/255.) green:(232/255.) blue:(160/255.) alpha:1.] set];
  [NSBezierPath fillRect:cellFrame];
  [[NSColor colorWithCalibratedRed:(101/255.) green:(159/255.) blue:(49/255.) alpha:1.] set];
  [NSBezierPath strokeRect:cellFrame];
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if (mIsIndeterminate) {
    [self drawIndeterminateWithFrame:cellFrame inView:controlView];
  } else {
    [super drawWithFrame:cellFrame inView:controlView];
  }
}

@end
