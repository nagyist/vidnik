//
//  VRVideoView.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/18/08.
//  Copyright 2008 David Phillip Oster. Open source under Apache license Documentation/Copying in this project
//

#import "VRVideoView.h"
#import "TDVideoView.h"
#import "TDCapture.h"
#import "TDQTKit.h"
#import "MovieView.h"
#import "QTMovie+Async.h"

@interface VRVideoView(PrivateMethods)
- (void)reinit;
@end
@implementation VRVideoView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self reinit];
  }
  return self;
}

- (void)dealloc {
  [mRecordView release];
  [mPlayView release];
  [super dealloc];
}


- (void)awakeFromNib {
  if (nil == mRecordView) {
    [self reinit];
  }
}

- (void)setCaptureSession:(TDCaptureSession *)captureSession {
  if (nil == mRecordView) {
    [self reinit];
  }
  [mRecordView setCaptureSession:captureSession];
}

- (QTMovie *)movie {
  return [mPlayView movie];
}

- (void)setMovie:(QTMovie *)movie {
  if (nil == mRecordView) {
    [self reinit];
  }
  [mPlayView setMovie:movie];
  if (movie) {
    [mPlayView setEditable:YES];
  }
  [mPlayView setHidden:(nil == movie)];
  [mRecordView setHidden:(nil != movie)];
}

- (IBAction)play:(id)sender {
  if ( ! [mPlayView isHidden]) {
    [mPlayView play:sender];
  }
}

- (IBAction)pause:(id)sender {
  if ( ! [mPlayView isHidden]) {
    [mPlayView pause:sender];
  }
}

- (IBAction)trim:(id)sender {
  if ( ! [mPlayView isHidden]) {
    [mPlayView trim:sender];
  }
}

- (IBAction)stepForward:(id)sender {
  if ( ! [mPlayView isHidden]) {
    [mPlayView stepForward:sender];
  }
}

- (IBAction)stepBackward:(id)sender {
  if ( ! [mPlayView isHidden]) {
    [mPlayView stepBackward:sender];
  }
}

- (IBAction)gotoBeginning:(id)sender {
  if ( ! [mPlayView isHidden]) {
    [mPlayView gotoBeginning:sender];
  }
}

- (IBAction)selectAll:(id)sender {
  QTMovie *movie = [self movie];
  QTTimeRange range;
  range.time = QTMakeTimeWithTimeInterval(0);
  range.duration = [movie duration];
  [mPlayView selectAll:sender];
  [movie setAttribute:[NSValue valueWithQTTimeRange:range]  forKey:QTMovieSelectionAttribute];
}

- (IBAction)selectNone:(id)sender {
  QTMovie *movie = [self movie];
  NSValue *selValue = [movie attributeForKey:QTMovieSelectionAttribute];
  if (selValue) {
    QTTimeRange range = [selValue QTTimeRangeValue];
    range.duration = QTMakeTimeWithTimeInterval(0);
    [movie setAttribute:[NSValue valueWithQTTimeRange:range]  forKey:QTMovieSelectionAttribute];
  }
  [mPlayView selectNone:sender];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  if ( ! [mPlayView isHidden]) {
    SEL action = [anItem action];
    if (@selector(selectNone:) == action) {
      QTMovie *movie = [self movie];
      NSValue *selValue = [movie attributeForKey:QTMovieSelectionAttribute];
      NSTimeInterval duration = 0;
      if (selValue) {
        QTTimeRange range = [selValue QTTimeRangeValue];
        if ( ! QTGetTimeInterval(range.duration, &duration) ) {
          duration = 0;
        }
      }
      return 0 != duration;
    } else if (@selector(selectAll:) == action) {
      QTMovie *movie = [self movie];
      NSValue *selValue = [movie attributeForKey:QTMovieSelectionAttribute];
      if (selValue) {
        QTTimeRange range = [selValue QTTimeRangeValue];
        return NSOrderedSame != QTTimeCompare([movie duration], range.duration);
      }
      return NO;
    }
    return [mPlayView validateMenuItem:anItem];
  } else if ( ! [mRecordView isHidden]) {
    return [mRecordView validateMenuItem:anItem];
  }
  return NO;
}

@end

@implementation VRVideoView(PrivateMethods)

- (NSRect)centeredFrame {
  NSRect bounds = [self bounds];
  NSRect frame;
  frame.size.width = 320;
  frame.size.height = 240;
  frame.origin.x = (bounds.size.width - frame.size.width)/2.;
  frame.origin.y = (bounds.size.height - frame.size.height)/2.;
  return frame;
}

- (void)reinit {
  [mRecordView release];
  mRecordView = [[gTDVideoView alloc] initWithFrame:[self centeredFrame]];
  [self addSubview:mRecordView];
  [mPlayView release];
  mPlayView = [[MovieView alloc] initWithFrame:[self centeredFrame]];
  [mPlayView setHidden:YES];
  [mPlayView setControllerVisible:NO];
  [self addSubview:mPlayView];
}

@end

#if 0
// button validation code.
  } else if (@selector(play:) == action ||
      @selector(pause:) == action ||
      @selector(gotoBeginning:) == action) {

    return ! [self isHidden] && nil != [self movie];

#endif

