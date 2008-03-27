//
//  UndoManager+Additions.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/5/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSUndoManager(TDAdditions)
- (BOOL)isUndoingOrRedoing;
@end
