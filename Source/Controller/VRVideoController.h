//
//  VRVideoController.h
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

#import <Cocoa/Cocoa.h>
#import "TDConstants.h"
#import "MoviePerformer.h"

@class VRVideoView;
@class VRVideoMeterView;
@class TDAudioView;
@class TDCaptureSession;
@class TDCaptureMovieFileOutput;
@class TDCaptureDeviceInput;
@class QTMovie;

@interface VRVideoController : NSResponder<MoviePerformer> {
 @private
  IBOutlet VRVideoView      *mVideoView;
  IBOutlet VRVideoMeterView *mVideoMeter;

  IBOutlet NSButton         *mRewindButton;
  IBOutlet NSButton         *mRecordButton;
  IBOutlet NSButton         *mNewButton;
  IBOutlet NSButton         *mPlayButton;

  IBOutlet NSTextField       *mRewindLabel;
  IBOutlet NSTextField       *mRecordLabel;
  IBOutlet NSTextField       *mPlayLabel;

  IBOutlet NSLevelIndicator  *mVolumeLevel;
  IBOutlet NSSlider          *mVolumeGain;
  IBOutlet NSButton          *mVolumeMin;
  IBOutlet NSButton          *mVolumeMax;

  IBOutlet id               mDelegate;  // weak
  NSTimer                   *mMetersTimer;

  TDCaptureSession          *mSession;
  TDCaptureMovieFileOutput  *mOutFile;
  TDCaptureDeviceInput      *mInVideoDev;
  // mInAudioDev may be nil camera supports audio directly
  TDCaptureDeviceInput      *mInAudioDev;
  NSURL                     *mOutURL;
  QTMovie                   *mMovie;
  BOOL                      mIsPlaybackMode;
  BOOL                      mIsRecording;
  BOOL                      mIsPlaying;

}

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (QTMovie *)movie;
- (void)setMovie:(QTMovie *)movie;

- (void)setNewMovieState;

- (IBAction)rewind:(id)sender;
- (IBAction)record:(id)sender;
- (IBAction)stopRecording:(id)sender;
- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)selectNone:(id)sender;
- (IBAction)togglePlay:(id)sender;
- (IBAction)volume0:(id)sender;
- (IBAction)volume1:(id)sender;
- (IBAction)trackVolume:(id)sender;
@end

@interface NSObject(VRVideoControllerDelegate)
- (void)didFinishVideoRecording:(NSURL *)url;
- (void)qtMovieChanged:(QTMovie *)movie userInfo:(NSMutableDictionary *)info;
@end
