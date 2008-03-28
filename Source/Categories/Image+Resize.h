//
//  Image+Resize.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/25/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


@interface NSImage(Resize)
- (NSImage *)conciseRepresentation;

- (NSImage *)resizedThumbnail;


@end
