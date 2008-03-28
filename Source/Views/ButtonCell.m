//
//  ButtonCell.m
//  Progress
//
//  Created by David Phillip Oster on 3/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
