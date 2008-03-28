//
//  TDCaptureMovieFileOutput.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDCaptureMovieFileOutput.h"
#import "TDQTKit.h"

@implementation TDCaptureMovieFileOutput
- (id)init {
  self = [super init];
  if (self) {
    mI = [[QTCaptureMovieFileOutput alloc] init];
  }
  return self;
}


- (void)dealloc {
  [mI release];
  [super dealloc];
}

- (void)setDelegate:(id)delegate {
  [mI setDelegate:delegate];
}

- (void)recordToOutputFileURL:(NSURL *)url {
  [mI recordToOutputFileURL:url];
}

- (NSTimeInterval)recordedDuration {
  NSTimeInterval val = 0;
  if (mI) {
    QTGetTimeInterval([(QTCaptureMovieFileOutput *) mI recordedDuration], &val);
  }
  return val;
}

- (UInt64)recordedFileSize {
  return [mI recordedFileSize];
}

@end
@implementation TDCaptureMovieFileOutput(Protected) 
- (id)impl {
  return mI;
}

- (id)initWithImpl:(id) impl {
  self = [super init];
  if (self) {
    mI = [impl retain];
  }
  return self;
}
 
@end
