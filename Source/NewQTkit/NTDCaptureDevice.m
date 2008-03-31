//
//  TDCaptureDevice.m
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

#import "TDCaptureDevice.h"
#import "TDQTKit.h"

Class gTDCaptureDeviceInput;

@implementation TDCaptureDevice

+ (void)initialize {
  gTDCaptureDeviceInput = self;
}

- (id)initWithDev:(id)dev{
  self = [super init];
  if (self) {
    mI = [dev retain];
  }
  return self;
}


- (void)dealloc {
  [mI release];
  [super dealloc];
}

- (void)close {
  [mI close];
}

- (BOOL)isOpen {
  return [mI isOpen];
}

- (BOOL)hasMediaType:(NSString *)mediaType {
  return [(QTCaptureDevice *) mI hasMediaType:mediaType];
}

@end
