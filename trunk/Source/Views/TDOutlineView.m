//
//  TDOutlineView.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/3/08.
//  Copyright 2008 Google Inc. All rights reserved.
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

// ### Actions
/* Discussion: our delegate is our controller. It isn't an NSRepsonder, so we
  explicitly pass actions and validations we want it to handle to it. 
 */
- (IBAction)copy:(id)sender {
  [[self delegate] copy:sender];
}

- (IBAction)cut:(id)sender {
  [[self delegate] cut:sender];
}


- (IBAction)paste:(id)sender {
  [[self delegate] paste:sender];
}


- (IBAction)delete:(id)sender {
  [[self delegate] delete:sender];
}

- (IBAction)newMovie:(id)sender {
  [[self delegate] newMovie:sender];
}

- (IBAction)trim:(id)sender {
  [[self delegate] trim:sender];
}

- (IBAction)selectAll:(id)sender {
  [[self delegate] selectAll:sender];
}

- (IBAction)selectNone:(id)sender {
  [[self delegate] selectNone:sender];
}


- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  return [[self delegate] validateMenuItem:anItem];
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

- (void)reloadData {
  static BOOL isInside = NO;
  if ( ! isInside) {
    isInside = YES;
    [super reloadData];
    isInside = NO;
  } else {
  NSLog(@"reloadData called while in a relaodData");
  }
}

@end
