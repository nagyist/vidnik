//
//  TDOutlineView.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/3/08.
//  Copyright 2008 Google Inc. All rights reserved.
//
#import "TDConstants.h"

#import <Cocoa/Cocoa.h>


@interface TDOutlineView : NSOutlineView
@end

@interface NSObject(TDOutlineViewDataSource)
- (void)willResignFirstResponder:(NSResponder *)responder;
- (void)didResignFirstResponder:(NSResponder *)responder;
- (NSArray *)draggedObjects;
- (void)removeObjects:(NSArray *)objects;

// ### Actions
- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;
- (IBAction)trim:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)selectNone:(id)sender;

@end
