//
//  TDOutlineView.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/3/08.
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
