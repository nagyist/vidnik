//
//  UndoManager+Additions.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/5/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "UndoManager+Additions.h"


@implementation NSUndoManager(TDAdditions)
- (BOOL)isUndoingOrRedoing {
  return [self isUndoing] || [self isRedoing];
}

@end
