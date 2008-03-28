//
//  TDModelUploadingAction.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/21/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
