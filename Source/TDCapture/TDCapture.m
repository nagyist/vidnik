//
//  TDCapture.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/15/08.
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

#import "TDCapture.h"

Class gTDCaptureMovieFileOutput;
Class gTDCaptureDeviceInput;
Class gTDCaptureSession;
Class gTDVideoView;

enum {
  kTDCaptureErrNoPath = 100,
  kTDCaptureErrNoBundle = 101,
  kTDCaptureErrNoLoad = 102,
  kTDCaptureErrNoClass = 103,
  kTDCaptureErrOldQuicktime = 104,
};


static NSString *TDCaptureErrorDescription(int code) {
  switch (code) {
  case kTDCaptureErrNoPath:   return NSLocalizedString(@"TDCaptureErrDescNoPath", @"");
  case kTDCaptureErrNoBundle: return NSLocalizedString(@"TDCaptureErrDescNoBundle", @"");
  case kTDCaptureErrNoLoad:   return NSLocalizedString(@"TDCaptureErrDescNoLoad", @"");
  case kTDCaptureErrNoClass:  return NSLocalizedString(@"TDCaptureErrDescNoClass", @"");
  case kTDCaptureErrOldQuicktime:  return NSLocalizedString(@"TDCaptureErrOldQuicktime", @"");
  }
  return nil;
}

static NSString *TDCaptureErrorReason(int code) {
  switch (code) {
  case kTDCaptureErrNoPath:   return NSLocalizedString(@"TDCaptureErrReasonNoPath", @"");
  case kTDCaptureErrNoBundle: return NSLocalizedString(@"TDCaptureErrReasonNoBundle", @"");
  case kTDCaptureErrNoLoad:   return NSLocalizedString(@"TDCaptureErrReasonNoLoad", @"");
  case kTDCaptureErrNoClass:  return NSLocalizedString(@"TDCaptureErrReasonNoClass", @"");
  case kTDCaptureErrOldQuicktime:  return NSLocalizedString(@"TDCaptureErrReasonOldQuicktime", @"");
  }
  return nil;
}

static NSString *TDCaptureErrorSuggestion(int code) {
  switch (code) {
  case kTDCaptureErrNoPath:   return NSLocalizedString(@"TDCaptureErrSuggestNoPath", @"");
  case kTDCaptureErrNoBundle: return NSLocalizedString(@"TDCaptureErrSuggestNoBundle", @"");
  case kTDCaptureErrNoLoad:   return NSLocalizedString(@"TDCaptureErrSuggestNoLoad", @"");
  case kTDCaptureErrNoClass:  return NSLocalizedString(@"TDCaptureErrSuggestNoClass", @"");
  case kTDCaptureErrOldQuicktime:  return NSLocalizedString(@"TDCaptureErrSuggestOldQuicktime", @"");
  }
  return nil;
}

static NSError *TDCaptureConstructErr(int code, id arg) {
  NSString *reason = TDCaptureErrorReason(code);
  if (reason && arg) {
    reason = [NSString stringWithFormat:reason, arg];
  }
  NSString *suggestion = TDCaptureErrorSuggestion(code);
  if (reason && suggestion) {
    suggestion = [NSString stringWithFormat:@"%@\n%@", reason, suggestion];
  } else if (nil == suggestion) {
    suggestion = reason;
  }
  if (suggestion && code) {
    suggestion = [NSString stringWithFormat:@"%@ (TDCapture:%d)", suggestion, code];
  }
  NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
    TDCaptureErrorDescription(code), NSLocalizedDescriptionKey,
    suggestion, NSLocalizedRecoverySuggestionErrorKey,
    arg, NSFilePathErrorKey, 
    nil];
  return [NSError errorWithDomain:@"TDCapture" code:code userInfo:info];
}

// Call this to initialize the TDCaptureInit system.
// We implement the grabber twice: once for 10.5 and up, once for 10.4.
// This code chooses the correct implementation.
// Note: the 10.4 grabber will actualy work in 10.5, but this make it easy
// to drop support when it is no longer appropriate.
// 3/21/08 : I'm dropping OldQTKit from the build. 
BOOL TDCaptureInit(NSError **errp) {
  NSError *err = nil;
  UInt32 qtVersion;
  OSStatus status = Gestalt(gestaltQuickTimeVersion, (SInt32 *) &qtVersion);
  if (noErr == status && qtVersion < 0x07200000) {
     // Use API introduced in QTKit 7.2.0
    err =  TDCaptureConstructErr(kTDCaptureErrOldQuicktime, nil);
  } else {
    NSString *kitName = @"NewQTKit";
    NSString *path = [[NSBundle mainBundle] pathForResource:kitName ofType:@"bundle" inDirectory:@"../PlugIns"];
    if (nil == err && nil == path) {
      err = TDCaptureConstructErr(kTDCaptureErrNoPath, kitName);
    }
    NSBundle *qtBundle = [NSBundle bundleWithPath:path];
    if (nil == err && nil == qtBundle) {
      err = TDCaptureConstructErr(kTDCaptureErrNoBundle, path);
    }
    if (nil == err && ! [qtBundle load]) {
      err = TDCaptureConstructErr(kTDCaptureErrNoLoad, path);
    }
    gTDCaptureMovieFileOutput = [qtBundle classNamed:@"TDCaptureMovieFileOutput"];
    gTDCaptureDeviceInput = [qtBundle classNamed:@"TDCaptureDeviceInput"];
    gTDCaptureSession = [qtBundle classNamed:@"TDCaptureSession"];
    gTDVideoView = [qtBundle classNamed:@"TDVideoView"]; 
    if(nil == err && ! (gTDCaptureMovieFileOutput && gTDCaptureDeviceInput && gTDCaptureSession && gTDVideoView)) {
      err = TDCaptureConstructErr(kTDCaptureErrNoClass, path);
    }
  }
  if (nil != err && nil != errp) {
    *errp = err;
  }
  return nil == err;
}

