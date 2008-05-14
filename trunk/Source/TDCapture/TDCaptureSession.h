//
//  TDCaptureSession.h
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

@class TDCaptureDeviceInput;
@class TDCaptureMovieFileOutput;

// I originally wrote a QTKit wrapper because I thought it was 10.5 only.
// I left this as separate code, becuase it makes very clear what the interface
// to QTKit is.
@interface TDCaptureSession : NSObject {
 @private
  id mI;  // implementation
}

- (BOOL)addInput:(TDCaptureDeviceInput *)inDev error:(NSError **)error;
- (BOOL)addOutput:(TDCaptureMovieFileOutput *)outFile error:(NSError **)error;

// My experience has been that if I hand an object to QTCaptureSession, it doesn't
// behave the same as one I ask QTCaptureSession for.
- (TDCaptureMovieFileOutput *)captureFileOutput;

- (BOOL)canRun;
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
