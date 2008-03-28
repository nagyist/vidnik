//
//  TDCapture.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/15/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

// will be initalized by TDCaptureInit
extern Class gTDCaptureMovieFileOutput;
extern Class gTDCaptureDeviceInput;
extern Class gTDCaptureSession;
extern Class gTDVideoView;


// Call this to initialize the TDCaptureInit system.
BOOL TDCaptureInit(NSError **errp);
