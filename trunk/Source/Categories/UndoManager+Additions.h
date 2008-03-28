//
//  UndoManager+Additions.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/5/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


@interface NSUndoManager(TDAdditions)
- (BOOL)isUndoingOrRedoing;
@end
