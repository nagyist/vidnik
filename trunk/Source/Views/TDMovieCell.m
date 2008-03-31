//
//  TDMovieCell.m
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

#import "TDMovieCell.h"
#import "TDModelMovieAdditions.h"
#import "TDModelUploadingAction.h"
#import "ProgressCell.h"

enum {
  kImageFrame,
  kTitleFrame,
  kProgressFrame,
  kNumFrames
};


@interface NSObject(TDMovieCellDelegate)
- (NSUInteger)hitTestForEvent:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView;

// given our frame rect, flesh out a C array of rects.
- (void)computeFrames:(NSRect *)outF cellFrame:(NSRect)cellFrame isFlipped:(BOOL)isFlipped;
@end

@implementation TDMovieCell

- (id)init {
  self = [super init];
  if (self) {
    [self setLineBreakMode:NSLineBreakByTruncatingTail];
    [self setSelectable:YES];
  }
  return self;
}

- (void)dealloc {
  [mThumbnail release];
  [mProgressCell release];
  [mAction release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
    TDMovieCell *cell = (TDMovieCell *)[super copyWithZone:zone];
    cell->mThumbnail = [mThumbnail copyWithZone:zone];
    cell->mProgressCell = [mProgressCell copyWithZone:zone];
    cell->mAction = [mAction copyWithZone:zone];
    [cell->mProgressCell setDelegate:cell->mAction];
    return cell;
}

- (NSImage *)thumbnail {
    return mThumbnail;
}


- (void)setThumbnail:(NSImage *)thumbnail {
  if (mThumbnail != thumbnail) {
    [mThumbnail autorelease];
    mThumbnail = [thumbnail retain];
  }
}

- (void)setTitle:(NSString *)title {
  [self setStringValue:title ? title : @""];
}

- (void)setCategory:(NSString *)category {
}

- (void)setKeywords:(NSArray *)keywords {
}

- (void)setDetails:(NSString *)details {
}

- (void)setMovieState:(ModelMovieState)movieState {
  mMovieState = movieState;
}

- (void)setUploadingAction:(TDModelUploadingAction *)action {
  [mAction autorelease];
  mAction = [action copy];
  [mProgressCell setDelegate:mAction];
}


- (void)setIndex:(int)index {
  mIndex = index;
}


- (void)setModelMovie:(TDModelMovie *)modelMovie {
  NSString *path = [modelMovie path];
  if (nil == path) {
    mMovieFilePresentState = kMovieFileAbsent;
  } else {
    mMovieFilePresentState = kMovieFilePresent;
  }
  [self setTitle:[modelMovie title]];
  [self setThumbnail:[modelMovie thumbnail]];
  [self setCategory:[modelMovie category]];
  [self setKeywords:[modelMovie keywords]];
  [self setDetails:[modelMovie details]];
  [self setMovieState:[modelMovie movieState]];
  [self setUploadingAction:[modelMovie uploadingAction]];
}

- (void)editWithFrame:(NSRect)cellFrame inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject event:(NSEvent *)theEvent {
  NSRect frames[kNumFrames];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:[controlView isFlipped]];
  [super editWithFrame:frames[kTitleFrame] inView: controlView editor:textObj delegate:anObject event: theEvent];
}

- (void)selectWithFrame:(NSRect)cellFrame inView:(NSView *)controlView editor:(NSText *)textObj delegate:(id)anObject start:(NSInteger)selStart length:(NSInteger)selLength {
  NSRect frames[kNumFrames];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:[controlView isFlipped]];
  [super selectWithFrame:frames[kTitleFrame] inView: controlView editor:textObj delegate:anObject start:selStart length:selLength];
}

- (void)drawBadge:(NSString *)badgeName withFrame:(NSRect)imageFrame inView:(NSView *)controlView {
  NSImage *badgeIcon = [NSImage imageNamed:badgeName];
  if (badgeIcon) {
    NSSize badgeSize = [badgeIcon size];
    NSPoint badgePoint = imageFrame.origin;
    badgePoint.x += (imageFrame.size.width - badgeSize.width)/2.;
    if ([controlView isFlipped]) {
      badgePoint.y += (imageFrame.size.height + badgeSize.height)/2.;
    }else{
      badgePoint.y -= (imageFrame.size.height + badgeSize.height)/2.;
    }
    [badgeIcon compositeToPoint:badgePoint operation:NSCompositeSourceOver];
  }
}


- (void)drawThumbnailWithFrame:(NSRect)imageFrame inView:(NSView *)controlView {
  if (mThumbnail) {
    NSPoint imagePoint = imageFrame.origin;
    if ([controlView isFlipped]) {
      imagePoint.y += (imageFrame.size.height + (4/2));
    }
    [mThumbnail compositeToPoint:imagePoint operation:NSCompositeSourceOver];
    if (kMovieFileAbsent == mMovieFilePresentState) {
      [self drawBadge:@"Missing" withFrame:imageFrame inView:controlView];
    } else if(kMovieFileNotYetDetermined == mMovieFilePresentState) {
      [self drawBadge:@"NotYetPresent" withFrame:imageFrame inView:controlView];
    }
  } else {
    imageFrame.size.height -= 5;
    if ([controlView isFlipped]) {
      imageFrame.origin.y += 5;
    }
    [[NSColor blackColor] set];
    [NSBezierPath fillRect:imageFrame];
    NSImage *newIcon = [NSImage imageNamed:@"RecordPreviewMovie"];
    if (newIcon) {
      imageFrame.origin.x += (imageFrame.size.width - [newIcon size].width)/2.;
      float yOffset = imageFrame.size.height - [newIcon size].height/2.;
      if ([controlView isFlipped]) {
        imageFrame.origin.y += yOffset;
      }else{
        imageFrame.origin.y -= yOffset;
      }
      [newIcon compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
  }
}

- (void)drawProgressWithFrame:(NSRect)progressFrame inView:(NSView *)controlView {
  if (nil != mAction) {
    if (nil == mProgressCell) {
      mProgressCell = [[ProgressCell alloc] init];
      [mProgressCell setDelegate:mAction];
    }
    [mProgressCell setMin:0 max:[mAction dataLength] startTime:[mAction startTime]];
    [mProgressCell setProgress:[mAction numberOfBytesSent] max:[mAction dataLength]];
    [mProgressCell drawWithFrame:progressFrame inView:controlView];
  } else if (nil != [mProgressCell delegate]){
    [mProgressCell setDelegate:nil];
  }
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  NSRect frames[kNumFrames];
  BOOL isFlipped = [controlView isFlipped];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:isFlipped];

  [self drawThumbnailWithFrame:frames[kImageFrame] inView:controlView];
  [self drawProgressWithFrame:frames[kProgressFrame] inView:controlView];
  [super drawWithFrame:frames[kTitleFrame] inView:controlView];
}

- (BOOL)trackMouse:(NSEvent *)event 
            inRect:(NSRect)cellFrame 
            ofView:(NSView *)controlView 
      untilMouseUp:(BOOL)flag {

  NSRect frames[kNumFrames];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:[controlView isFlipped]];
  NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];
  BOOL isFlipped = [controlView isFlipped];
  if (NSMouseInRect(point, frames[kProgressFrame], isFlipped)) {
    return [mProgressCell trackMouse:event 
                              inRect:frames[kProgressFrame] 
                              ofView:controlView 
                        untilMouseUp:flag];
  } else if (NSMouseInRect(point, frames[kTitleFrame], isFlipped)) {
    return [super trackMouse:event 
                      inRect:frames[kTitleFrame] 
                      ofView:controlView 
                untilMouseUp:flag];
  }
  return YES;
}

- (NSUInteger)hitTestForEvent:(NSEvent *)event 
                       inRect:(NSRect)cellFrame
                       ofView:(NSView *)controlView {
  NSRect frames[kNumFrames];
  BOOL isFlipped = [controlView isFlipped];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:isFlipped];

  NSPoint point = [controlView convertPoint:[event locationInWindow] fromView:nil];
  if (NSMouseInRect(point, frames[kProgressFrame], isFlipped)) {
    return [mProgressCell hitTestForEvent:event 
                                   inRect:frames[kProgressFrame] 
                                   ofView:controlView];
  } else if (NSMouseInRect(point, frames[kTitleFrame], isFlipped)) {
    // At this point, the cellFrame has been modified to exclude the portion for
    // the mThumbnail. Let the superclass handle the hit testing at this point.
    // Tiger compatible method
    if ([[NSTextFieldCell class] instancesRespondToSelector:@selector(hitTestForEvent:inRect:ofView:)]) {
      return [super hitTestForEvent:event inRect:frames[kTitleFrame] ofView:controlView];
    }
  } else if (NSMouseInRect(point, cellFrame, isFlipped)) {
    return 1; // i.e.: NSCellHitContentArea;
  }
  return 0;
}


// given our frame rect, flesh out a C array of rects.
- (void)computeFrames:(NSRect *)outF cellFrame:(NSRect)cellFrame isFlipped:(BOOL)isFlipped {
  NSSize imageSize = [self thumbnailSize];
  imageSize.height += 4;  // margin
  imageSize.width += 4;  // margin
  NSDivideRect(cellFrame, &outF[kImageFrame], &outF[kTitleFrame], imageSize.height, (isFlipped ? NSMinYEdge : NSMaxYEdge));
  NSDivideRect(outF[kImageFrame], &outF[kImageFrame], &outF[kProgressFrame], imageSize.width, NSMinXEdge);
  outF[kProgressFrame].size.height -= 2;
  outF[kProgressFrame].origin.x += 2;
  outF[kProgressFrame].origin.y += 2;
}

- (NSRect)imageRectForBounds:(NSRect)cellFrame {
  NSRect frames[kNumFrames];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:YES];
  return frames[kImageFrame];
}

// We could manually implement expansionFrameWithFrame:inView: and
// drawWithExpansionFrame:inView: or just properly implement titleRectForBounds
// to get expansion tooltips to automatically work for us
- (NSRect)titleRectForBounds:(NSRect)cellFrame {
  NSRect frames[kNumFrames];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:YES];
  return frames[kTitleFrame];
}

// See also: - (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item in TDPlayListController.m
- (NSSize)cellSize {
  return NSMakeSize(176., 54);
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
  return [self cellSize];
}

- (NSSize)thumbnailSize {
  return mThumbnail ? [mThumbnail size] : [[self class] defaultThumbnailSize];
}

+ (NSSize)defaultThumbnailSize {
  return NSMakeSize(32*1.333, 32.);
}

// we store the index as the tag of the items, so contextual menus can discover what got clicked.
- (NSMenu *)menu {
  NSMenu *menu = [[[super menu] copy] autorelease];
  int i, iCount = [menu numberOfItems];
  for (i = 0; i < iCount; ++i) {
    NSMenuItem *item = [menu itemAtIndex:i];
    [item setTag:mIndex];
  }
  return menu;
}

@end
