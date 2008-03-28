//
//  TDOutlineView.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/3/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


@interface TDOutlineView : NSOutlineView
- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)screenPoint operation:(NSDragOperation)operation;
@end

@interface NSObject(TDOutlineViewDataSource)
- (NSArray *)draggedObjects;
- (void)removeObjects:(NSArray *)objects;

- (void)willResignFirstResponder:(NSResponder *)responder;
- (void)didResignFirstResponder:(NSResponder *)responder;
@end
