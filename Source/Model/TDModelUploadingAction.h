//
//  TDModelUploadingAction.h
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

#import <Cocoa/Cocoa.h>

// non-nil, on an TDModelMovie only while it is being uploaded.
// not saved to disk

@interface TDModelUploadingAction : NSObject<NSCopying> {
  unsigned long long mNumberOfBytesSent;
  unsigned long long mDataLength;
  NSTimeInterval mStartTime;
  id mDelegate; // for cancel
}

- (unsigned long long)numberOfBytesSent;
- (void)setNumberOfBytesSent:(unsigned long long)numberOfBytesSent;

- (unsigned long long)dataLength;
- (void)setDataLength:(unsigned long long)dataLength;

- (NSTimeInterval)startTime;

- (id)delegate;
- (void)setDelegate:(id)delegate;

// note: this will receive userCancelled:(ProgressCell *)
// when the user presses the cancel button.
- (void)userCancelled:(id)sender;
@end
@interface NSObject(TDModelUploadingActionDelegate)
- (void)userCancelledUploading:(id)sender;
@end
