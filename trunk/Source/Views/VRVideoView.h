//
//  VRVideoView.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/18/08.
//  Copyright 2008 David Phillip Oster. Open source under Apache license Documentation/Copying in this project
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
