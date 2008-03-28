//
//  TDOutlineView.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/3/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDOutlineView.h"


@implementation TDOutlineView

// This NSOutlineView subclass is necessary to delete items by dragging them to
// the trash.
// For any other operation, pass the message to the superclass 

- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation {
  if (operation == NSDragOperationDelete) {
    // Tell all of the dragged nodes to remove themselves from the model.
    NSArray *selection = [[self dataSource] draggedObjects];
    if (selection) {
      [[self dataSource] removeObjects:selection];
    }
  } else {
    [super draggedImage:image endedAt:screenPoint operation:operation];
  }
}

- (BOOL)resignFirstResponder {
  id delegate = [self delegate];
  if ([delegate respondsToSelector:@selector(willResignFirstResponder:)]) {
    [delegate willResignFirstResponder:self];
  }
  BOOL val = [super resignFirstResponder];
  delegate = [self delegate];
  if (val && [delegate respondsToSelector:@selector(didResignFirstResponder:)]) {
    [delegate didResignFirstResponder:self];
  }
  return val;
}

@end
