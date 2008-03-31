//
//  VRVideoMeterView.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/18/08.
//  Copyright 2008 David Phillip Oster. Open source under Apache license Documentation/Copying in this project
//

#import "VRVideoMeterView.h"
#import "StringFormat.h"
#import "TDQTKit.h"

enum {
  kTextWidth = 90,
  kTextRightMargin = 4,
  kBarXMargin = 10,
  kBarYMargin = 6
};


@interface VRVideoMeterView(Private)
- (void)reinit;
- (void)drawRecordRect:(NSRect)rect;
- (void)drawPlayRect:(NSRect)rect;
- (void)getFrames:(NSRect *)frames;
- (float)nowPos;
- (void)setNowPos:(float)nowPos;
- (void)setNowPosDuringTrack:(float)nowPos;
- (void)mouseDownPlay:(NSEvent*)theEvent;
- (void)mouseDownRecord:(NSEvent*)theEvent;
- (void)sendSelectionDuringTrackToDelegate;
@end

static NSDictionary *gLeftAttributes = nil;
static NSDictionary *gRightAttributes = nil;

@implementation VRVideoMeterView

enum {
  kNow, kStart, kEnd, kWholeBar, kPreBar, kSelBar, kPostBar, kTimeText, kFrameCount,
  kPre = kNow + 1, kPost, kSel, kWidthCount
};


- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self reinit];
    if (nil == gLeftAttributes) {
      NSParagraphStyle *leftPara = [NSParagraphStyle defaultParagraphStyle];
      gLeftAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: 
        leftPara, NSParagraphStyleAttributeName,
        nil];
    }
    if (nil == gRightAttributes) {
      NSMutableParagraphStyle *rightPara = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
      [rightPara setAlignment:NSRightTextAlignment];
      gRightAttributes = [[NSDictionary alloc] initWithObjectsAndKeys: 
        rightPara, NSParagraphStyleAttributeName,
        nil];
    }
  }
  return self;
}

- (void)dealloc {
  [super dealloc];
}

- (void)awakeFromNib {
  [self reinit];
}

- (void)drawRect:(NSRect)rect {
  if (mIsPlayMode) {
    [self drawPlayRect:rect];
  } else {
    [self drawRecordRect:rect];
  }
}

- (BOOL)mouseDownCanMoveWindow {
	return NO;
}

- (void)mouseDown:(NSEvent*)theEvent {
  if (mIsPlayMode) {
    [self mouseDownPlay:theEvent];
  } else {
    [self mouseDownRecord:theEvent];
  }
}

- (id)delegate {
  return mDelegate;
}
- (void)setDelegate:(id)delegate {
  mDelegate = delegate;
}

- (BOOL)isPlayMode {
  return mIsPlayMode;
}
- (void)setPlayMode:(BOOL)isPlayMode {
  if (mIsPlayMode != isPlayMode) {
    if (isPlayMode ) { 
      // transitioning from record to play. Reset
      [self setRecordedDuration:0];
      [self setRecordedFileSize:0];
    }
    mIsPlayMode = isPlayMode;
  }
}

- (NSTimeInterval)current {
  return mCurrent;
}

- (void)setCurrent:(NSTimeInterval)current {
  if ([self current] != current) {
    mCurrent = current;
    [self setNeedsDisplay:YES];
  }
}

- (void)setSelectionStart:(NSTimeInterval)startSecs end:(NSTimeInterval)endSecs {
  NSTimeInterval duration = [self duration];
  if (0 < duration && 0 <= startSecs && startSecs <= endSecs && endSecs <= duration) {
    float xStart = startSecs / duration;
    float xEnd = endSecs / duration;
    if ( ! (xStart == mStartPos && xEnd == mEndPos)) {
      mStartPos = xStart;
      mEndPos = xEnd;
      [self setNeedsDisplay:YES];
    }
  }
}

- (NSTimeInterval)duration {
  return mDuration;
}

- (void)setDuration:(NSTimeInterval)duration {
  mDuration = duration;
  if (mDuration < mCurrent) {
    mCurrent = mDuration;
  }
  [self setNeedsDisplay:YES];
}

- (NSTimeInterval)recordedDuration {
  return mRecordedDuration;
}

- (void)setRecordedDuration:(NSTimeInterval)recordedDuration {
  if (mRecordedDuration != recordedDuration) {
    mRecordedDuration = recordedDuration;
    [self setNeedsDisplay:YES];
  }
}

- (UInt64)recordedFileSize {
  return mRecordedFileSize;
}

- (void)setRecordedFileSize:(UInt64)recordedFileSize {
  if (mRecordedFileSize != recordedFileSize) {
    mRecordedFileSize = recordedFileSize;
    [self setNeedsDisplay:YES];
  }
}


@end

@implementation VRVideoMeterView(Private)

- (void)reinit {
  mStartMarker = [NSImage imageNamed:@"StartMarker"];
  mEndMarker = [NSImage imageNamed:@"EndMarker"];
  mNowMarker = [NSImage imageNamed:@"NowMarker"];

  mStartPos = 0.0;
  mEndPos = 1.0;
  mDuration = 1.0;
  mCurrent = 0.4;
  mIsPlayMode = NO;
}

- (void)drawRecordRect:(NSRect)rect {
  NSRect frame = [self bounds];
  [NSGraphicsContext saveGraphicsState];
  if (mRecordedFileSize) {
    NSString *fileSize = [NSString stringFromFileSize:mRecordedFileSize];
    NSRect sizeR = frame;
    sizeR.origin.x += 20;
    sizeR.size.width = 120;
    [fileSize drawInRect:sizeR withAttributes:gLeftAttributes];
  }
  if (mRecordedDuration) {
    NSString *duration = [NSString stringFromTime:mRecordedDuration];
    NSRect durationR = frame;
    durationR.origin.x = durationR.origin.x + durationR.size.width - (120 + kTextRightMargin);
    durationR.size.width = 120;
    [duration drawInRect:durationR withAttributes:gRightAttributes];
  }
  [NSGraphicsContext restoreGraphicsState];
}

- (void)drawPlayRect:(NSRect)rect {
  NSRect frames[kFrameCount];
  [self getFrames:frames];

  // Note: at one time we used a pattern pen to draw the meter background, but
  //  it had artifacts while the window was being resized.
  [NSGraphicsContext saveGraphicsState];

  NSImage *unSelImage = [NSImage imageNamed:@"tanBar"];
  NSImage *selImage = [NSImage imageNamed:@"tanBarSel"];
  if (unSelImage && selImage) {
    NSRect unSelImageFrame;
    unSelImageFrame.origin = NSMakePoint(0,0);
    unSelImageFrame.size = [unSelImage size];

    NSRect selImageFrame;
    selImageFrame.origin = NSMakePoint(0,0);
    selImageFrame.size = [selImage size];

    // draw the selection: pre, sel, post
    [unSelImage drawInRect:frames[kPreBar] fromRect:unSelImageFrame operation:NSCompositeSourceOver fraction:1.0];
    [selImage drawInRect:frames[kSelBar] fromRect:selImageFrame operation:NSCompositeSourceOver fraction:1.0];
    [unSelImage drawInRect:frames[kPostBar] fromRect:unSelImageFrame operation:NSCompositeSourceOver fraction:1.0];
  }

  // draw the markers: start, end, now
  [mStartMarker compositeToPoint:frames[kStart].origin operation:NSCompositeSourceAtop];
  [mEndMarker compositeToPoint:frames[kEnd].origin operation:NSCompositeSourceAtop];
  [mNowMarker compositeToPoint:frames[kNow].origin operation:NSCompositeSourceAtop];

  NSString *current = [NSString stringFromTimeShort:mCurrent];
  NSString *duration = [NSString stringFromTimeShort:mDuration];
  NSString *s = [NSString stringWithFormat:@"%@/%@", current, duration];
  [s drawInRect:frames[kTimeText] withAttributes:gRightAttributes];

  [NSGraphicsContext restoreGraphicsState];
}

// compute the metrics for our pieces: widths for segments of background,
// bounding rectangles for markers.
// offsetting markers of the background leads to improper graphic updating.
- (void)getFrames:(NSRect *)frames {
  float widths[kWidthCount];
  NSRect frame = [self bounds];

  frames[kTimeText] = frame;
  frames[kTimeText].origin.x = frames[kTimeText].origin.x + frames[kTimeText].size.width - (kTextWidth + kTextRightMargin);
  frames[kTimeText].size.width = kTextWidth;

  frame.size.width -= (kTextWidth + kBarXMargin*2);
  frame.origin.x += kBarXMargin;
  frames[kWholeBar] = frame;


  widths[kNow] = frame.size.width * [self nowPos];
  widths[kPre] = frame.size.width * mStartPos;
  widths[kPost] = frame.size.width * ( 1. - mEndPos);
  widths[kSel] = frame.size.width - (widths[kPre] + widths[kPost]);


  frames[kPreBar] = NSMakeRect(frames[kWholeBar].origin.x, frames[kWholeBar].origin.y+1, 
      widths[kPre], frames[kWholeBar].size.height-2);
  frames[kSelBar] = NSMakeRect(frames[kWholeBar].origin.x + widths[kPre], frames[kWholeBar].origin.y+1, 
      widths[kSel], frames[kWholeBar].size.height-2);
  frames[kPostBar] = NSMakeRect(frames[kWholeBar].origin.x + widths[kPre] + widths[kSel], frames[kWholeBar].origin.y+1, 
      widths[kPost], frames[kWholeBar].size.height-2);

  NSSize startSize = [mStartMarker size];
  frames[kStart] = NSMakeRect(frame.origin.x + widths[kPre] - startSize.width, 
              frame.origin.y, startSize.width, startSize.height);
  NSSize endSize = [mEndMarker size];
  frames[kEnd] = NSMakeRect(frame.origin.x + widths[kPre] + widths[kSel],
              frame.origin.y, endSize.width, endSize.height);
  NSSize nowSize = [mNowMarker size];
  frames[kNow] = NSMakeRect(frame.origin.x + widths[kNow] - nowSize.width/2, 
              frame.origin.y + kBarYMargin, nowSize.width, nowSize.height);
}


- (float)nowPos {
  return mCurrent / mDuration;
}

- (void)setNowPos:(float)nowPos {
  float newCurrent = fmax(0., fmin(1.0, nowPos)) * mDuration;
  if (newCurrent != mCurrent) {
    NSRect frames[kFrameCount];
    [self getFrames:frames];
    NSRect oldCurrent = frames[kNow];
    mCurrent = newCurrent;
    [self getFrames:frames];
    if ( ! NSEqualRects(oldCurrent, frames[kNow])) {
      [self setNeedsDisplayInRect:oldCurrent];
      [self setNeedsDisplayInRect:frames[kNow]];
    }
  }
}

- (void)setNowPosDuringTrack:(float)nowPos {
  [self setNowPos:nowPos];
  if ([mDelegate respondsToSelector:@selector(currentChangedDuringDrag:)]) {
    [mDelegate currentChangedDuringDrag:self];
  }
}


- (void)mouseDownRecord:(NSEvent*)theEvent {
}

typedef enum TrackEnum{
  kTrackNow, kTrackStart, kTrackEnd, kTrackNothing
}TrackEnum;

- (void)mouseDownPlay:(NSEvent*)theEvent {
  NSRect frames[kFrameCount];
  [self getFrames:frames];
	NSPoint where0 = [self convertPoint:[theEvent locationInWindow] fromView:nil];
  TrackEnum track = kTrackNothing;
  if ([self mouse:where0 inRect:frames[kNow]]) {
    track = kTrackNow;
  } else if ([self mouse:where0 inRect:frames[kStart]]) {
    track = kTrackStart;
  } else if ([self mouse:where0 inRect:frames[kEnd]]) {
    track = kTrackEnd;
  } else if ([self mouse:where0 inRect:frames[kWholeBar]]) {
    [self setNowPos:fminf(1.f, fmaxf(0.0f, 1.0 + where0.x - frames[kWholeBar].origin.x - [mNowMarker size].width/2.0) / frames[kWholeBar].size.width)];
    [self setNeedsDisplayInRect:frames[kWholeBar]];
    track = kTrackNow;
  } else {
    track = kTrackNothing;
  }
  if (kTrackNothing != track) {
    float x;
    switch(track) {
    case kTrackNow:
      x = [self nowPos];
      if ([mDelegate respondsToSelector:@selector(willDragCurrent:)]) {
        [mDelegate willDragCurrent:self];
      }
      break;
    case kTrackStart: x = mStartPos;
      break;
    case kTrackEnd: x = mEndPos ;
      break;
    default:
      break;
    }
    while (nil != (theEvent = [NSApp nextEventMatchingMask:NSLeftMouseDownMask|NSLeftMouseDraggedMask|NSLeftMouseUpMask 
                                untilDate:[NSDate distantFuture] 
                                inMode:NSEventTrackingRunLoopMode 
                                dequeue:YES]) &&
                                (NSLeftMouseUp != [theEvent type])) {
      NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
      NSDisableScreenUpdates();
      NSPoint where = [self convertPoint:[theEvent locationInWindow] fromView:nil];
      float dxInPixels = where.x - where0.x;
      float dxInRatio = dxInPixels / frames[kWholeBar].size.width;
      float xNow = fminf(1.0f, fmaxf(0.f, x+dxInRatio));
      switch(track) {
      case kTrackNow:
        [self setNowPosDuringTrack:xNow];
        break;
      case kTrackStart:
        mStartPos = xNow; 
        if (mEndPos < mStartPos) {
          mEndPos = mStartPos;
        }
        [self sendSelectionDuringTrackToDelegate];
        [self setNowPosDuringTrack:xNow];
        break;
      case kTrackEnd:
        mEndPos = xNow;
        if (mEndPos < mStartPos) {
          mStartPos = mEndPos;
        }
        [self sendSelectionDuringTrackToDelegate];
        [self setNowPosDuringTrack:xNow];
        break;
      default:
        break;
      }
      [self setNeedsDisplay:YES];
      NSEnableScreenUpdates();
      [pool release];
    }
    if ([mDelegate respondsToSelector:@selector(didDragCurrent:)]) {
      [mDelegate didDragCurrent:self];
    }
  }
}

- (void)sendSelectionDuringTrackToDelegate {
  if ([mDelegate respondsToSelector:@selector(setSelectionStart:end:)] &&
    0 < mDuration &&
    0 <= mStartPos && mStartPos <= mEndPos && mEndPos <= 1.0) {
    [mDelegate setSelectionStart:mDuration*mStartPos end:mDuration*mEndPos];
  }
}

@end



NSString * const kVideoMeterWillDragCurrentNotification = @"kVideoMeterWillDragCurrentNotification";
NSString * const kVideoMeterDidDragCurrentNotification = @"kVideoMeterDidDragCurrentNotification";



