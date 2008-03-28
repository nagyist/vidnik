//
//  TDCaptureMovieFileOutput.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


// Wrap OS X 10.5 only QTKit class QTCaptureMovieFileOutput, 
// so we can re-implement for Tiger
@interface TDCaptureMovieFileOutput : NSObject {
 @private
  id mI;  // implementation
}

- (void)setDelegate:(id)delegate;
- (void)recordToOutputFileURL:(NSURL *)url;

- (NSTimeInterval)recordedDuration;
- (UInt64)recordedFileSize;

@end
// for implementors. Client programs should not call these.
@interface TDCaptureMovieFileOutput(Protected) 
- (id)impl;
- (id)initWithImpl:(id) impl;
@end
