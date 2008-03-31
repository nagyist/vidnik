//
//  TDModelUploadingAction.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/21/08.
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

#import "TDModelUploadingAction.h"


@implementation TDModelUploadingAction

- (id)init {
  self = [super init];
  if (self) {
    mStartTime = [NSDate timeIntervalSinceReferenceDate];
  }
  return self;
}

- (id)copyWithZone:(NSZone *)zone {
  TDModelUploadingAction *val = [[TDModelUploadingAction allocWithZone:zone] init];
  val->mNumberOfBytesSent = mNumberOfBytesSent;
  val->mDataLength = mDataLength;
  val->mDelegate = mDelegate;
  val->mStartTime = mStartTime;
  return val;
}

- (unsigned long long)numberOfBytesSent {
  return mNumberOfBytesSent;
}

- (void)setNumberOfBytesSent:(unsigned long long)numberOfBytesSent {
  mNumberOfBytesSent = numberOfBytesSent;
}


- (unsigned long long)dataLength {
  return mDataLength;
}

- (void)setDataLength:(unsigned long long)dataLength {
  mDataLength = dataLength;
}

- (NSTimeInterval)startTime {
  return mStartTime;
}


- (id)delegate {
  return mDelegate;
}

- (void)setDelegate:(id)delegate {
  mDelegate = delegate;
}

// note: this will receive userCancelled:(ProgressCell *)
// when the user presses the cancel button.
- (void)userCancelled:(id)sender {
  [mDelegate userCancelledUploading:sender];
}

@end
