//
//  Image+Resize.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/25/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "Image+Resize.h"


@implementation NSImage(Resize)

// since we'll only showing the thumbnail small from now on, throw away the big
// representations
- (NSImage *)conciseRepresentation {
  NSImage *val = [[self copy] autorelease];
  NSArray *representations = [val representations];
  int i, iCount = [representations count];
  NSMutableArray *removeThese = [NSMutableArray array];
  for (i = 0; i < iCount; ++i) {
    NSImageRep *rep = [representations objectAtIndex:i];
    NSSize siz = [rep size];
    if (100 <= siz.width || 100 <= siz.height) {
      [removeThese addObject:rep];
    }
  }
// removing a rep randomizes the order so we save the ones to go in aux structure.
  iCount = [removeThese count];
  for (i = 0; i < iCount && 0 < [[val representations] count]; ++i) {
    NSImageRep *rep = [removeThese objectAtIndex:i];
    [val removeRepresentation:rep];
  }
  return val;
}

- (NSImage *)resizedThumbnail {
  NSSize size = [self size];
  if (size.height <= 32 && size.width <= 32*1.333) {
    return self;
  }
  NSImage *m = [[self copy] autorelease];
  [m setScalesWhenResized:YES];
  NSSize newSizeH = NSMakeSize(size.width * (32.*1.333)/size.width, 32);
  NSSize newSizeW = NSMakeSize(32, size.height * 32/size.width);
  NSSize newSize;
  if (newSizeH.width * newSizeH.height < newSizeW.width * newSizeW.height) {
    newSize = newSizeW;
  } else {
    newSize = newSizeH;
  }
  [m setSize:newSize];
  // Calling conciseRepresentation here appears to priduce an undrawable image.
  return m;
}

@end
