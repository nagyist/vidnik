//
//  Image+Resize.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/25/08.
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
