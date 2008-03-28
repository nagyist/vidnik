//
//  TDVideoView.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

@class TDCaptureSession;

// Wrap OS X 10.5 only QTKit class QTVideoView, 
// so we can re-implement for Tiger
@interface TDVideoView : NSView {
 @private
  id mI;  // implementation
}
- (void)setCaptureSession:(TDCaptureSession *)captureSession;

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@end
