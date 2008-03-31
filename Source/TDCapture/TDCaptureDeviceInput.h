//
//  TDCaptureDeviceInput.h
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

@class TDCaptureDevice;

// Wrap OS X 10.5 only QTKit class QTCaptureDeviceInput, 
// so we can re-implement for Tiger
@interface TDCaptureDeviceInput : NSObject {
 @private
  id mI;  // implementation
}

+ (id)defaultInputDeviceWithMediaType:(NSString *)mediaType error:(NSError **)error;
- (id)initMediaType:(NSString *)mediaType error:(NSError **)errp;
- (TDCaptureDevice *)device;
- (BOOL)hasMediaType:(NSString *)mediaType;
- (NSArray *)connections;
- (void)configureOptionsForConnections;

+ (NSString *)tdMediaTypeSound;
- (NSString *)tdMediaTypeSound;
+ (NSString *)tdMediaTypeMuxed;
- (NSString *)tdMediaTypeMuxed;
+ (NSString *)tdMediaTypeVideo;
- (NSString *)tdMediaTypeVideo;
+ (NSString *)tdMediaTypeVideoOrMuxed;
- (NSString *)tdMediaTypeVideoOrMuxed;

@end
@interface TDCaptureDeviceInput(Protected) 
- (id)impl;
@end

extern Class gTDCaptureDeviceInput;

#define TDMediaTypeSound  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeSound]
#define TDMediaTypeMuxed  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeMuxed]
#define TDMediaTypeVideo  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeVideo]
#define TDMediaTypeVideoOrMuxed  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeVideoOrMuxed]
