//
//  ProgressCell.h
//  Progress
//
//  Created by David Phillip Oster on 3/12/08.
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

#import <Cocoa/Cocoa.h>

@class ProgressIndicatorCell;

// This is a NSCell with nested NSCells. 
// It is a complex progress meter. When used in a Control, its interface is
// simple. Example:
// [cell setMin:0 max:123000]; // initializes,
// [cell setProgress:120 max:123000]; // advances the progress meter.
//
// However, when used in a table the caller must use:
// [cell setMin:0 max:123000]; // initializes,
//    [mProgressCell setMin:0 max:maximum];
//    [mProgressCell setStartTime:[[a objectAtIndex:2] floatValue]];
//    [mProgressCell setProgress:[[a objectAtIndex:0] intValue] max:maximum];
// [cell setProgress:120 max:123000]; // advances the progress meter.
//
@interface ProgressCell : NSCell {
  NSString             *mTimeRemaining;
  NSButtonCell         *mCancelButton;
  ProgressIndicatorCell *mProgress;
  id                   mDelegate; // WEAK
  NSTimeInterval       mStartTime;
  SInt64  mMin;
  SInt64  mMax;
  SInt64  mValue;
  BOOL    mOmitThroughput;
  BOOL    mIsHidden;
}
// set to NIL to restore default clock.
+ (void)setTimeIntervalSource:(id)source;


- (id)init;

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

- (BOOL)trackMouse:(NSEvent *)event 
            inRect:(NSRect)cellFrame 
            ofView:(NSView *)controlView 
      untilMouseUp:(BOOL)flag;

// allow building the unit tests on 10.5, building at all on 10.4
#if defined(NSINTEGER_DEFINED) && defined(MAC_OS_X_VERSION_10_5) &&  MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_5
- (NSUInteger)hitTestForEvent:(NSEvent *)event 
                       inRect:(NSRect)cellFrame
                       ofView:(NSView *)controlView;
#endif

// Call this to put this cell in the cancelled state.
- (void)cancel:(id)sender;

// Call this to begin the progress session. pass 0 to use NOW as the start time.
- (void)setMin:(SInt64)aMin max:(SInt64)aMax startTime:(NSTimeInterval)startTime;

// Call this to begin the progress session. assumes min of 0. 
// assumes NOW as the start time.
- (void)setMax:(SInt64)aMax;

// Call this to begin the progress session. Use a max smaller than min
// to get the indeterminate bar
- (void)setMin:(SInt64)aMin max:(SInt64)aMax;

// Call this for successive steps. when max becomes > min, you'll
// get the determinate bar
- (void)setProgress:(SInt64)aVal max:(SInt64)aMax;

// defaults to YES.
// If YES, report bytes per second to user.
- (void)setHasThroughput:(BOOL)hasThroughput;
- (BOOL)hasThroughput;

- (BOOL)isHidden;
- (void)setHidden:(BOOL)isHidden;

- (BOOL)isIndeterminate;
- (void)setIndeterminate:(BOOL)isIndeterminate;

- (NSTimeInterval)startTime;
- (void)setStartTime:(NSTimeInterval)startTime;

- (id)delegate;
- (void)setDelegate:(id)delegate;

@end
@interface NSObject(ProgressCellDelegate)
// will call this delegate method if user presses cancel button.
- (void)userCancelled:(id)progress;
@end
// for unit testing, it is convenient to pass in a simulated clock.
@interface NSObject(ProgressCellTimeIntervalSinceReferenceDate)
- (NSTimeInterval)timeIntervalSinceReferenceDate;
@end
