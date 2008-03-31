//
//  VRVideoMeterView.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/18/08.
//  Copyright 2008 David Phillip Oster. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

// time meter for a recorded video segment.
// lets the user click and drag the start, end of a selection,
// lets the user click and drag the current marker.
@interface VRVideoMeterView : NSView {
 @private
  float mStartPos; // in 0..1
  float mEndPos;   // in 0..1
  // for recording
  NSTimeInterval  mRecordedDuration;
  UInt64          mRecordedFileSize;
  UInt64          mDiskFreeSize;
 // for playback
  NSTimeInterval mCurrent;
  NSTimeInterval mDuration;    // in seconds
  NSImage *mStartMarker;
  NSImage *mEndMarker;
  NSImage *mNowMarker;
  IBOutlet id mDelegate;
  BOOL  mIsPlayMode;
}
- (id)delegate;
- (void)setDelegate:(id)delegate;

- (BOOL)isPlayMode;
- (void)setPlayMode:(BOOL)isPlayMode;

- (NSTimeInterval)current;
- (void)setCurrent:(NSTimeInterval)current;

- (NSTimeInterval)duration;
- (void)setDuration:(NSTimeInterval)duration;

- (void)setSelectionStart:(NSTimeInterval)startSecs end:(NSTimeInterval)endSecs;

- (NSTimeInterval)recordedDuration;
- (void)setRecordedDuration:(NSTimeInterval)recordedDuration;

- (UInt64)recordedFileSize;
- (void)setRecordedFileSize:(UInt64)recordedFileSize;

@end

@interface NSObject(VRVideoMeterViewDelegateMethods)
- (void)willDragCurrent:(VRVideoMeterView *)meter;
- (void)didDragCurrent:(VRVideoMeterView *)meter;
- (void)currentChangedDuringDrag:(VRVideoMeterView *)meter;
- (void)setSelectionStart:(NSTimeInterval)start end:(NSTimeInterval)end;
@end
