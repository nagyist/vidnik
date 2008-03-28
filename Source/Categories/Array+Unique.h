//
//  Array+Unique.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/26/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


@interface NSArray(Unique)
// returns copy of self, preserving order, but with caseInsensitive duplicates removed.
- (NSArray *)unique;
@end
