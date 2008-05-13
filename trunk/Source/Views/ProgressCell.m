//
//  ProgressCell.m
//  Progress
//
//  Created by David Phillip Oster on 3/11/08.
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

#import "ProgressCell.h"
#import "ProgressIndicatorCell.h"
#import "Friendly.h"
#import "ButtonCell.h"

enum {
  kButtonFrame,
  kIndicatorFrame,
  kTextFrame,
  kNumFrames
};

enum {
  kCancelButtonDim = 12
};

@interface ProgressCell(Private)

+ (NSTimeInterval)timeIntervalSinceReferenceDate;
- (NSTimeInterval)timeIntervalSinceReferenceDate;

- (void)reinit;

- (void)setTimeRemaining:(NSString *)timeRemaining;

// given our frame rect, flesh out a C array of rects.
- (void)computeFrames:(NSRect *)outF cellFrame:(NSRect)cellFrame isFlipped:(BOOL)isFlipped;

- (void)updateTimeRemaining;

@end

static id gTimeSource;

@implementation ProgressCell
+ (void)setTimeIntervalSource:(id)source {
  gTimeSource = source;
}


- (id)init {
  self = [super init];
  if (self) {
    [self reinit];
  }
  return self;
}

- (void)awakeFromNib {
  [self reinit];
}

-(void)dealloc {
  [mTimeRemaining release];
  [mCancelButton release];
  [mProgress release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  ProgressCell *val = [[ProgressCell alloc] init];
  val->mTimeRemaining = [mTimeRemaining copy];
  [val->mProgress setMinValue:[mProgress minValue]];
  [val->mProgress setMaxValue:[mProgress maxValue]];
  [val->mProgress setDoubleValue:[mProgress doubleValue]];
  [val->mCancelButton setTarget:val];
  val->mDelegate = mDelegate;
  val->mStartTime = mStartTime;
  val->mMin = mMin;
  val->mMax = mMax;
  val->mValue = mValue;
  val->mOmitThroughput = mOmitThroughput;
  val->mIsHidden = mIsHidden;
  return val;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
  if ( ! [self isHidden]) {
    NSRect frames[kNumFrames];
    [self computeFrames:frames cellFrame:cellFrame isFlipped:[controlView isFlipped]];
    [mCancelButton drawWithFrame:frames[kButtonFrame] inView:controlView];
    [mProgress drawWithFrame:frames[kIndicatorFrame] inView:controlView];
    NSDictionary *gDict = nil;
    if (nil == gDict) {
      NSMutableParagraphStyle *paraStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
      [paraStyle setLineBreakMode:NSLineBreakByTruncatingHead];
      gDict = [[NSDictionary dictionaryWithObjectsAndKeys:
      [NSFont userFontOfSize:10.], NSFontAttributeName,
      paraStyle, NSParagraphStyleAttributeName,
      nil] retain];
    }
    [mTimeRemaining drawInRect:frames[kTextFrame] withAttributes:gDict];
  }
}


- (BOOL)trackMouse:(NSEvent *)event 
            inRect:(NSRect)cellFrame 
            ofView:(NSView *)controlView 
      untilMouseUp:(BOOL)flag {
  
  if ( ! [self isHidden]) {
    NSRect frames[kNumFrames];
    [self computeFrames:frames cellFrame:cellFrame isFlipped:[controlView isFlipped]];
    NSPoint locationInCellFrame = [controlView convertPoint:[event locationInWindow] fromView:nil];
    if (NSMouseInRect(locationInCellFrame, frames[kButtonFrame], [controlView isFlipped]) ) {
      return [mCancelButton trackMouse:event 
                                inRect:frames[kButtonFrame]
                                ofView:controlView 
                          untilMouseUp:flag];
    }
  }
  return YES;
}

#if defined(NSINTEGER_DEFINED) && defined(MAC_OS_X_VERSION_10_5) &&  MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
- (NSUInteger)hitTestForEvent:(NSEvent *)event 
                       inRect:(NSRect)cellFrame
                       ofView:(NSView *)controlView {
  if ([self isHidden]) {
    return 1;
  }
  NSRect frames[kNumFrames];
  [self computeFrames:frames cellFrame:cellFrame isFlipped:[controlView isFlipped]];
  NSPoint locationInCellFrame = [controlView convertPoint:[event locationInWindow] fromView:nil];
  if (NSMouseInRect(locationInCellFrame, frames[kButtonFrame], [controlView isFlipped]) ) {
    return 5; // i.e.: NSCellHitContentArea | NSCellHitTrackableArea; (OS X 10.4 compatibility)
  }
  return 1;
}
#endif

// when the user presses the cancel button, we'll send userCancelled: to our
// delegate
- (IBAction)cancel:(id)sender {
  [self setProgress:mMin max:mMax];
  [self setIndeterminate:NO];
  [mCancelButton setEnabled:NO];
  [self setTimeRemaining:@""];
  if (mDelegate != sender && 
    [mDelegate respondsToSelector:@selector(userCancelled:)]) {

    [mDelegate userCancelled:self];
  }
}

- (void)setMin:(SInt64)aMin max:(SInt64)aMax startTime:(NSTimeInterval)startTime {
  mMin = aMin;
  mValue = aMin;
  mMax = aMax;
  [mProgress setMinValue:mMin];
  if (mMin < mMax) {
    [mProgress setMaxValue:mMax];
    [mProgress setDoubleValue:mValue];
  } else {
    [mProgress setMaxValue:mMin+1];
    [mProgress setDoubleValue:mMin];
  }
  [mCancelButton setEnabled:YES];
  if (0 == startTime) {
    mStartTime = [self timeIntervalSinceReferenceDate];
    [self setIndeterminate:YES];
  } else {
    mStartTime = startTime;
  }
}

- (void)setMin:(SInt64)aMin max:(SInt64)aMax {
  [self setMin:aMin max:aMax startTime:0];
}

- (void)setMax:(SInt64)aMax {
  [self setMin:0 max:aMax startTime:0];
}


- (void)setProgress:(SInt64)aVal max:(SInt64)aMax {
  if (aVal != mValue || aMax != mMax) {
    if  (aMax < aVal) {
      aVal = aMax;
    }
    mValue = aVal;
    if (mMin < mMax) {
      if (mMax != aMax) {
        mMax = aMax;
        [mProgress setMaxValue:mMax];
      }
      if (mMin < mMax && mMin <= mValue) {
        [self updateTimeRemaining];
      }
      float fractionDone = (1. * mValue) / (mMax - mMin);
      if (0. < fractionDone) {
        if([self isIndeterminate]) {
          [self setIndeterminate:NO];
        }
      }
      [mProgress setDoubleValue:mValue];
      if (mValue == mMax) {
        [mCancelButton setEnabled:NO];
        [self setTimeRemaining:@""];
      }
    }
  }
}

- (NSTimeInterval)startTime {
  return mStartTime;
}

- (void)setStartTime:(NSTimeInterval)startTime {
  mStartTime = startTime;
}


- (void)setHidden:(BOOL)flag {
  if (flag != mIsHidden) {
    mIsHidden = flag;
    [[self controlView] setNeedsDisplay:YES];
  }
}

- (BOOL)isHidden {
  return mIsHidden;
}

- (void)setHasThroughput:(BOOL)hasThroughput {
  mOmitThroughput = ! hasThroughput;
}

- (BOOL)hasThroughput {
  return ! mOmitThroughput;
}

- (id)delegate {
  return mDelegate;
}

- (void)setDelegate:(id)delegate {
  mDelegate = delegate;
}

- (BOOL)isIndeterminate {
  return [mProgress isIndeterminate];
}

- (void)setIndeterminate:(BOOL)isIndeterminate {
  [mProgress setIndeterminate:isIndeterminate];
}

@end
@implementation ProgressCell(Private)

+ (NSTimeInterval)timeIntervalSinceReferenceDate {
  if (gTimeSource) {
    return [gTimeSource timeIntervalSinceReferenceDate];
  }
  return [NSDate timeIntervalSinceReferenceDate];
}

- (NSTimeInterval)timeIntervalSinceReferenceDate {
  return [[self class] timeIntervalSinceReferenceDate];
}

- (void)reinit {
  [self setTimeRemaining:@""];
  [mCancelButton release];
  mCancelButton = [[ButtonCell alloc] initImageCell:[NSImage imageNamed:@"CancelButton"]];
  [mCancelButton setImagePosition:NSImageOnly];
  [mCancelButton setBordered:NO];
  [mCancelButton setAlternateImage:[NSImage imageNamed:@"CancelButtonPressed"]];
  [mCancelButton setButtonType:NSMomentaryPushInButton];
  [mCancelButton setTarget:self];
  [mCancelButton setAction:@selector(cancel:)];
  [mProgress release];
  mProgress = [[ProgressIndicatorCell alloc] init];
}

- (void)setTimeRemaining:(NSString *)timeRemaining {
  [mTimeRemaining autorelease];
  mTimeRemaining = [timeRemaining copy];
}



- (void)computeFrames:(NSRect *)outF cellFrame:(NSRect)cellFrame isFlipped:(BOOL)isFlipped {
  NSRect majorFrame;
//  cellFrame.size.height -= 5.;
  NSDivideRect(cellFrame, &outF[kButtonFrame], &majorFrame, kCancelButtonDim, NSMaxXEdge);
  majorFrame.size.width -= 5.;
  NSDivideRect(majorFrame, &outF[kIndicatorFrame], &outF[kTextFrame], 21., (isFlipped ? NSMinYEdge : NSMaxYEdge));
  outF[kButtonFrame].size.height = kCancelButtonDim;
  outF[kButtonFrame].origin.y = outF[kIndicatorFrame].origin.y + 2 - (outF[kButtonFrame].size.height - outF[kIndicatorFrame].size.height)/2;
}

- (void)updateTimeRemaining {
  if (mMin < mMax) {
    float fractionDone = (1. * mValue) / (mMax - mMin);
    if (0. < fractionDone) {
      NSTimeInterval secondsSoFar = [self timeIntervalSinceReferenceDate] - mStartTime;
      NSTimeInterval projectedTotalTime = secondsSoFar / fractionDone;
      NSTimeInterval timeRemaining = projectedTotalTime - secondsSoFar;
      NSString *timeString = FriendlyStringFromTime(timeRemaining);
      NSString *timeRemainingS = @"";
      if (0 < [timeString length]) {
        if ([self hasThroughput] && 5. < secondsSoFar) {
          SInt64 amountSoFar = mValue - mMin;
          float bytesPerSecond = amountSoFar / secondsSoFar; 

          timeRemainingS = [NSString stringWithFormat:NSLocalizedString(@"remaining: %@ (%@/sec)", @""), 
            timeString, FriendlyBytes(bytesPerSecond)];
        } else {
          timeRemainingS = [NSString stringWithFormat:NSLocalizedString(@"remaining: %@", @""), 
            timeString];
        }
      }
      [self setTimeRemaining:timeRemainingS];
    }
  }
}


@end
