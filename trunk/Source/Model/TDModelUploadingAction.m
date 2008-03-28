//
//  TDModelUploadingAction.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/21/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
