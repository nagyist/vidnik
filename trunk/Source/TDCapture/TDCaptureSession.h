//
//  TDCaptureSession.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

@class TDCaptureDeviceInput;
@class TDCaptureMovieFileOutput;

// Wrap OS X 10.5 only QTKit class QTCaptureSession, 
// so we can re-implement for Tiger
@interface TDCaptureSession : NSObject {
 @private
  id mI;  // implementation
}
- (BOOL)addInput:(TDCaptureDeviceInput *)inDev error:(NSError **)error;
- (BOOL)addOutput:(TDCaptureMovieFileOutput *)outFile error:(NSError **)error;

// My experience has been that if I hand an object to QTCaptureSession, it doesn't
// behave the same as one I ask QTCaptureSession for.
- (TDCaptureMovieFileOutput *)captureFileOutput;

- (BOOL)isRunning;
- (void)startRunning;
- (void)stopRunning;

- (float)masterRecordVolume;
- (void)setMasterRecordVolume:(float)masterRecordVolume;
- (float)audioPowerLevel;

// Configure file format to 640x480, MPEG4, AAC Stereo
- (void)configureOutputs;

+ (NSString *)runtimeErrorNotification;
- (NSString *)runtimeErrorNotification;

+ (NSString *)runtimeErrorKey;
- (NSString *)runtimeErrorKey;

@end

@interface TDCaptureSession(Protected) 
- (id)impl;
@end

extern Class gTDCaptureSession;


#define TDCaptureSessionRuntimeErrorNotification [(TDCaptureSession *)gTDCaptureSession  runtimeErrorNotification]
#define TDCaptureSessionErrorKey [(TDCaptureSession *)gTDCaptureSession runtimeErrorKey]
