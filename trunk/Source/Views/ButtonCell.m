//
//  ButtonCell.m
//  Progress
//
//  Created by David Phillip Oster on 3/13/08.
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

#import "ButtonCell.h"


@implementation ButtonCell
// I couldn't get the standard tracker to work. This subclass works well enough
- (BOOL)trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)flag {
  NSWindow *win = [controlView window];
  BOOL isInside = NO;
  do {
    NSPoint locationInCellFrame = [controlView convertPoint:[event locationInWindow] fromView:nil];
    if (isInside != NSMouseInRect(locationInCellFrame, cellFrame, [controlView isFlipped]) ) {
      isInside = ! isInside;
      [self setHighlighted:isInside];
      [controlView setNeedsDisplayInRect:cellFrame];
    }
    event = [win nextEventMatchingMask:(NSLeftMouseDraggedMask  | NSLeftMouseUpMask) 
                             untilDate:[NSDate distantFuture] 
                                inMode:NSEventTrackingRunLoopMode 
                               dequeue:YES];
  } while (event && NSLeftMouseDraggedMask == [event type]);

  if (isInside) {
    isInside = ! isInside;
    [self setHighlighted:isInside];
    [controlView setNeedsDisplayInRect:cellFrame];
    SEL action = [self action];
    if (action) {
      [[self target] performSelector:[self action] withObject:self];
    }
  }
  return YES;
}


@end
