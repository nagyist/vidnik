//
//  VRVideoView.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/18/08.
//  Copyright 2008 David Phillip Oster. 
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

@class QTMovie;
@class MovieView;
@class TDVideoView;
@class TDCaptureSession;

// This class exists so we can alternate between recording, playing, and displaying error messages.
@interface VRVideoView : NSView {
 @private
  TDVideoView* mRecordView;
  MovieView* mPlayView;
}
- (QTMovie *)movie;
- (void)setMovie:(QTMovie *)movie;
- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)gotoBeginning:(id)sender;
- (IBAction)trim:(id)sender;
- (IBAction)stepForward:(id)sender;
- (IBAction)stepBackward:(id)sender;
- (IBAction)selectAll:(id)sender;
- (IBAction)selectNone:(id)sender;

- (void)setCaptureSession:(TDCaptureSession *)captureSession;

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@end
