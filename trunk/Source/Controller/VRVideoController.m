//
//  VRVideoController.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
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

#import "VRVideoController.h"
#import "TDCapture.h"
#import "TDCaptureSession.h"
#import "TDCaptureMovieFileOutput.h"
#import "TDCaptureDevice.h"
#import "TDCaptureDeviceInput.h"
#import "TDConfiguration.h"
#import "TDConstants.h"
#import "TDModelDate.h"
#import "QTMovie+Async.h"
#import "String+Path.h"
#import "TDModelMovie.h"
#import "TDQTKit.h"
#import "VRVideoMeterView.h"
#import "VRVideoView.h"


@interface VRVideoController(PrivateMethods)
- (void)attemptToGrabDevice:(NSTimer *)unused;
- (BOOL)isRecording;
- (BOOL)isPlaying;
- (BOOL)isPlaybackMode;
- (void)setPlaybackMode:(BOOL)isPlaybackMode;
- (void)startRecording;
- (void)stopRecording;
- (void)startPlaying;
- (void)stopPlaying;
- (NSURL *)nextOutURL;
- (void)metersTimerInvalidate;
- (BOOL)presentError:(NSError *)err;
- (void)updateButtonState;
- (void)updateSubViewsState;
@end

@implementation VRVideoController

- (void)awakeFromNib {
  NSError *err = nil;
  NSNotificationCenter *nc =[NSNotificationCenter defaultCenter];
  [nc addObserver:self
         selector:@selector(windowWillClose:) 
             name:NSWindowWillCloseNotification 
           object:[mVideoView window]];

  mSession = [[gTDCaptureSession alloc] init];

  [nc addObserver:self
        selector:@selector(sessionRuntimeError:) 
            name:TDCaptureSessionRuntimeErrorNotification
          object:mSession];

  id outFile = [[[gTDCaptureMovieFileOutput alloc] init] autorelease];
  if (outFile) {
    [outFile setDelegate:self];
    [mSession addOutput:outFile error:&err];
    mOutFile = [[mSession captureFileOutput] retain];
  }
  // I.B. in 10.4 doesn't let me make this control un-clickable
  [mVolumeLevel setEnabled:NO];
  [mVolumeLevel setFloatValue:10.];

  [mVideoView setCaptureSession:mSession];
  [self updateButtonState];
  [self attemptToGrabDevice:nil];
  if (nil == mMetersTimer) {
    mMetersTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 
                                              target:self 
                                            selector:@selector(metersTimer:)
                                            userInfo:nil 
                                             repeats:YES] retain];
  }
}

- (void)dealloc {
  NSNotificationCenter *nc =[NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  // view will be released by window.
  [self metersTimerInvalidate];
  [mSession release];
  [mOutFile release];
  [mInVideoDev release];
  [mInAudioDev release];
  [mMovie release];
  [super dealloc];
}

- (void)windowWillClose:(NSNotification *)notification {
  [mSession stopRunning]; 
  [self metersTimerInvalidate];
  if ([[mInVideoDev device] isOpen]) {
    [[mInVideoDev device] close];
  }
  if ([[mInAudioDev device] isOpen]) {
    [[mInAudioDev device] close];
  }
}

- (id)delegate {
  return mDelegate;
}

- (void)setDelegate:(id)delegate {
  mDelegate = delegate;
}

- (QTMovie *)movie {
  return mMovie;
}

- (void)setMovie:(QTMovie *)movie {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  if (mMovie) {
    [nc removeObserver:self name:QTMovieEditedNotification object:mMovie];
    [nc removeObserver:self name:QTMovieRateDidChangeNotification object:mMovie];
    [nc removeObserver:self name:QTMovieVolumeDidChangeNotification object:mMovie];
  }
  [mMovie autorelease];
  mMovie = [movie retain];
  if (mMovie) {
    [nc addObserver:self 
           selector:@selector(movieEditedNotification:) 
               name:QTMovieEditedNotification 
             object:mMovie];
    [nc addObserver:self 
           selector:@selector(movieRateDidChangeNotification:) 
               name:QTMovieRateDidChangeNotification 
             object:mMovie];
    [nc addObserver:self 
           selector:@selector(movieVolumeDidChangeNotification:) 
               name:QTMovieVolumeDidChangeNotification 
             object:mMovie];
  }
  [self setPlaybackMode:(nil != mMovie)];
  [mVideoView setMovie:mMovie];
  [self updateSubViewsState];
}

- (void)setSelectionStart:(NSTimeInterval)startSecs end:(NSTimeInterval)endSecs {
  QTTime start = QTMakeTimeWithTimeInterval(startSecs);
  QTTime duration = QTMakeTimeWithTimeInterval(endSecs - startSecs);
  [mMovie setSelection:QTMakeTimeRange(start, duration)];
  [mVideoMeter setSelectionStart:startSecs end:endSecs];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  BOOL val = NO;
  if ([self isPlaybackMode]) {
    return [mVideoView validateMenuItem:anItem];
  } else {
    SEL action = [anItem action];
    if (@selector(record:) == action) {
      val = ! [self isRecording];
    } else if (@selector(stopRecording:) == action) {
      val = [self isRecording];
    }
  }
  return val;
}

- (IBAction)rewind:(id)sender {
  [self stopRecording];
  [self setPlaybackMode:YES];
  [mVideoView gotoBeginning:self];
  if ([self isPlaying]) {
    [self stopPlaying];
  }
  [mVideoMeter setCurrent:0.];
  [self updateButtonState];
}

- (IBAction)record:(id)sender {
  [self setPlaybackMode:NO];
  if ([self isRecording]) {
    [self stopRecording];
  } else {
    [self startRecording];
  }
  [self updateButtonState];
}

- (IBAction)stopRecording:(id)sender {
  [self stopRecording];
  [self updateButtonState];
}


- (void)setNewMovieState {
  [self setPlaybackMode:NO];
  [self stopRecording];
  [self updateButtonState];
}

// called from play button.
- (IBAction)togglePlay:(id)sender {
  [self stopRecording];
  [self setPlaybackMode:YES];
  if ([self isPlaying]) {
    [self stopPlaying];
  } else {
    [self startPlaying];
  }
  [self updateButtonState];
}

- (IBAction)stop:(id)sender {
  [self stopRecording];
  [self setPlaybackMode:YES];
  [self stopPlaying];
  [self updateButtonState];
}

- (IBAction)play:(id)sender {
  [self stopRecording];
  [self setPlaybackMode:YES];
  [self startPlaying];
  [self updateButtonState];
}

- (IBAction)pause:(id)sender {
  [self stop:sender];
}

- (IBAction)volume0:(id)sender {
  [mSession setMasterRecordVolume:0.0];
  [mVolumeGain setFloatValue:0.0];
}

- (IBAction)volume1:(id)sender {
  float maxValue = [mVolumeGain maxValue];
  [mSession setMasterRecordVolume:maxValue];
  [mVolumeGain setFloatValue:maxValue];
}

- (IBAction)trackVolume:(id)sender {
  if (!mIsPlaybackMode) {
    [mSession setMasterRecordVolume:[sender floatValue]];
  }
}

- (IBAction)selectAll:(id)sender {
  [self stopRecording];
  [self setPlaybackMode:YES];
  [self setSelectionStart:0 end:[mVideoMeter duration]];
  [self updateButtonState];
}

- (IBAction)selectNone:(id)sender {
  [self stopRecording];
  [self setPlaybackMode:YES];
  [self setSelectionStart:[mVideoMeter current] end:[mVideoMeter current]];
  [self updateButtonState];
}

- (void)step:(int)count {
  if ([self isPlaybackMode]) {
    if (0 < count) {
      for ( ; count; --count) {
        [mVideoView stepForward:self];
      }
    } else if (count < 0) {
      for ( ; count; ++count) {
        [mVideoView stepBackward:self];
      }
    }
  }
}

- (void)trim:(id)sender {
  if ([self isPlaybackMode]) {
    [mVideoView trim:self];
  }
}


// first argument is actually a TDCaptureMovieFileOutput
- (void)captureOutput:(id)captureOutput  
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL 
                     forConnections:(NSArray *)connections 
                         dueToError:(NSError *)error {

  if (nil == error) {
    QTMovie *mov = [QTMovie asyncMovieWithURL:outputFileURL error:&error];
    if (mov) {
      [self setMovie:mov];
      if ([mDelegate respondsToSelector:@selector(didFinishVideoRecording:)]) {
        [mDelegate didFinishVideoRecording:outputFileURL];
      }
    }
  }
  if (error) {
    [self stopRecording:nil];
    [self presentError:error];
  }
} 

- (void)sessionRuntimeError:(NSNotification *)n {
  NSDictionary *info = [n userInfo];
  NSError *err = [info objectForKey:TDCaptureSessionErrorKey];
  [self presentError:err];
}

@end

@implementation VRVideoController(PrivateMethods)
// and if we can't grab it, then try again a few seconds later
- (void)attemptToGrabDevice:(NSTimer *)unused {
  NSError *err = nil;
  if (nil == mInVideoDev) {
    mInVideoDev = [[gTDCaptureDeviceInput defaultInputDeviceWithMediaType:TDMediaTypeVideo error:&err] retain];
    if (mInVideoDev) {
      if (mInVideoDev) {
        mInAudioDev = [[gTDCaptureDeviceInput defaultInputDeviceWithMediaType:TDMediaTypeSound error:&err] retain];
      }
    } else {
      mInVideoDev = [[gTDCaptureDeviceInput defaultInputDeviceWithMediaType:TDMediaTypeMuxed error:&err] retain];
    }
    if (mInVideoDev) {
      [mInVideoDev configureOptionsForConnections];
      [mSession addInput:mInVideoDev error:&err];
    }
    if (nil == err && mInAudioDev) {
      [mInAudioDev configureOptionsForConnections];
      [mSession addInput:mInAudioDev error:&err];
    }
    if (nil == err) {
      if (nil == mInVideoDev) {
        [NSTimer scheduledTimerWithTimeInterval:2.1 
                                         target:self 
                                       selector:@selector(attemptToGrabDevice:) 
                                       userInfo:nil 
                                        repeats:NO];
      } else {
        [mSession configureOutputs];
        [mSession startRunning];
        [self updateButtonState];
      }
    }
    if (nil != err) {
      [self presentError:err];
      [[mVideoView window] performClose:self];
      NSLog(@"%@", err);
    }
  }
}

- (void)metersTimerInvalidate {
  if (mMetersTimer) {
    [mMetersTimer invalidate];
    [mMetersTimer release];
    mMetersTimer = nil;
  }
}

- (BOOL)presentError:(NSError *)err {
  BOOL didSome = NO;
  if (err) { 
    NSResponder *delegate = [self delegate];
    if (delegate != self &&
      [delegate respondsToSelector:@selector(presentError:)]) {
      didSome = [delegate presentError:err];
    } else {
      didSome = [[NSDocumentController sharedDocumentController] presentError:err];
    }
  }
  return didSome;
}

- (void)updateVideoMeter {
  NSTimeInterval current = 0;
  if (mIsPlaybackMode && QTGetTimeInterval([mMovie currentTime], &current)) {
    [mVideoMeter setCurrent:current];
  }
}

- (void)updateAudioMeter {
  if (!mIsPlaybackMode) {
    float audioPowerLevel = [mSession audioPowerLevel];
    // decibels is negative number from MIN_FLOAT to 3.
    [mVolumeLevel setFloatValue:(pow(10., audioPowerLevel / 20.) * 20.)];
  } 
}

- (void)updateDurationMeter {
  if (!mIsPlaybackMode && mIsRecording) {
    [mVideoMeter setRecordedDuration:[mOutFile recordedDuration]];
    [mVideoMeter setRecordedFileSize:[mOutFile recordedFileSize]];
  }
}

- (void)metersTimer:(NSTimer *)timer {
  [self updateVideoMeter];
  [self updateAudioMeter];
  [self updateDurationMeter];
}


- (BOOL)isRecording {
  return mIsRecording;
}

- (BOOL)isPlaying {
  return mIsPlaying;
}

- (void)startRecording {
  if ( ! mIsRecording) {
    if ([mSession canRun]) {
      [mOutURL release];
      mOutURL = [[self nextOutURL] retain];
      if (mOutURL) {
        [mOutFile recordToOutputFileURL:mOutURL];
        NSString *path = [mOutURL path];
        if (path) {
          [[NSWorkspace sharedWorkspace] noteFileSystemChanged:path];
        }
        mIsRecording = YES;
        [self setPlaybackMode:NO];
        [NSApp setApplicationIconImage:[NSImage imageNamed: @"AppRecord"]];
      }
    } else {
      NSError *err = [NSError errorWithDomain:kTDAppDomain code:kNoCameraErr userInfo:nil];
      [self presentError:err];
    }
  }
}

- (void)stopRecording {
  if (mIsRecording) {
    mIsRecording = NO;
    [mOutFile recordToOutputFileURL:nil];
    [NSApp setApplicationIconImage:[NSImage imageNamed: @"NSApplicationIcon"]];
  }
}

- (void)startPlaying {
  mIsPlaying = YES;
  [self setPlaybackMode:YES];
  [mVideoView play:self];
}

- (void)stopPlaying {
  mIsPlaying = NO;
  [self setPlaybackMode:YES];
  [mVideoView pause:self];
}

- (void)movieEditedNotification:(NSNotification *)notify {
  if ([self isPlaybackMode]) {
    [self updateSubViewsState];
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObject:self forKey:@"controller"];
    [[self delegate] qtMovieChanged:[notify object] userInfo:dict];
  }
}

- (void)movieRateDidChangeNotification:(NSNotification *)notify {
  NSDictionary *info = [notify userInfo];
  NSNumber *newRate = [info objectForKey:QTMovieRateDidChangeNotificationParameter];
  float rate = [newRate floatValue];
  if (0.0 == rate && mIsPlaying) {
    [self stopPlaying];
    [self updateButtonState];
  } else if (0.0 != rate && ! mIsPlaying) {
    [self startPlaying];
    [self updateButtonState];
  }
}

- (void)movieVolumeDidChangeNotification:(NSNotification *)notify {
  QTMovie *movie = [notify object];
  if (movie) {
// TODO: movieVolumeDidChangeNotification
  }
}

- (NSURL *)nextOutURL {
  NSString *dateS = [[TDModelDate date] asSimpleString];
  NSString *tdFolder = [TDConfig() movieFolderPath];
  NSError *err = nil;
  if ( ! [TDConfig() validateMovieFolderPath:&tdFolder error:&err]) {
    [self presentError:err];
    return nil;
  } else {
    NSString *path = [NSString stringWithFormat:@"%@/%@.mov", tdFolder, dateS];
    return [NSURL fileURLWithPath:path];
  }
}

- (BOOL)isPlaybackMode {
  return mIsPlaybackMode;
}

- (void)setPlaybackMode:(BOOL)isPlaybackMode {
  if (isPlaybackMode != mIsPlaybackMode) {
    if ( !isPlaybackMode) {
      [mMovie autorelease];
      mMovie = nil;
    }
    [mVideoView setMovie:mMovie];
    mIsPlaybackMode = isPlaybackMode;
    [self updateSubViewsState];
  }
}

// called when transitioning from movie to movie, or from record to play state.
- (void)updateSubViewsState {
  BOOL isPlaybackMode = [self isPlaybackMode];
  if (isPlaybackMode && [mSession isRunning]) {
    [mSession stopRunning];
  } else if ( ! isPlaybackMode && ! [mSession isRunning]) {
    [mSession startRunning];
  }
  [mVideoMeter setCurrent:0.0];
  NSTimeInterval duration = 1.0;
  if (QTGetTimeInterval([mMovie duration], &duration)) {
    [mVideoMeter setDuration:(mMovie ? duration : 1.0)];
  }
  [mVideoMeter setPlayMode:isPlaybackMode];
  if (isPlaybackMode) {
    NSTimeInterval start = 0; 
    NSTimeInterval end = 0;
    if ( ! (mMovie &&
      QTGetTimeInterval([mMovie selectionStart], &start) && 
      QTGetTimeInterval([mMovie selectionEnd], &end))) {

      start = 0.;
      if ( ! QTGetTimeInterval([mMovie duration], &end)) {
        end = 0.;
      }
    }
    [mVideoMeter setSelectionStart:start end:end];
  }
  [self updateButtonState];
}

- (void)updateButtonState {
  [mPlayButton setHidden: ! mIsPlaybackMode];
  [mPlayLabel setHidden: ! mIsPlaybackMode];
  [mRewindButton setHidden: ! mIsPlaybackMode];
  [mRewindLabel setHidden: ! mIsPlaybackMode];

  [mRecordButton setHidden:mIsPlaybackMode];
  [mRecordLabel setHidden:mIsPlaybackMode];
  [mVolumeLevel setHidden:mIsPlaybackMode];
  [mVolumeGain setHidden:mIsPlaybackMode];
  [mVolumeMin setHidden:mIsPlaybackMode];
  [mVolumeMax setHidden:mIsPlaybackMode];

  if (mIsPlaybackMode) {
    if (mIsPlaying) {
      [mPlayButton setImage:[NSImage imageNamed:@"Pause"]];
      [mPlayLabel setStringValue:NSLocalizedString(@"Pause", @"Pause button")];
    } else {
      [mPlayButton setImage:[NSImage imageNamed:@"Play"]];
      [mPlayLabel setStringValue:NSLocalizedString(@"Play", @"Play button")];
    }
  } else {
    if (mIsRecording) {
      [mRecordButton setImage:[NSImage imageNamed:@"RecordOn"]];
    } else {
      [mRecordButton setImage:[NSImage imageNamed:@"Record"]];
    }
  }
}



- (void)currentChangedDuringDrag:(VRVideoMeterView *)meter {
  [mMovie setCurrentTime:QTMakeTimeWithTimeInterval([meter current])];
}


- (void)willDragCurrent:(VRVideoMeterView *)meter {
  [self stopPlaying];
  [self updateButtonState];
}

- (void)didDragCurrent:(VRVideoMeterView *)meter {
  [self currentChangedDuringDrag:meter];
}

// we will be called back through this method. so we define it even though it does nothing.
- (void)modelMovieChanged:(TDModelMovie *)mm userInfo:(NSMutableDictionary *)info {
}

// we will be called back through this method. so we define it even though it does nothing.
- (void)qtMovieChanged:(QTMovie *)movie userInfo:(NSMutableDictionary *)info {
}

@end
