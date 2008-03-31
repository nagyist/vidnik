//
//  ProgressIndicatorCell.m
//  Progress
//
//  Created by David Phillip Oster on 3/12/08.
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
