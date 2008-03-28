//
//  TDCaptureDevice.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>


// Wrap OS X 10.5 only QTKit class QTCaptureDevice, 
// so we can re-implement for Tiger
@interface TDCaptureDevice : NSObject {
 @private
  id mI;  // implementation
}

- (id)initWithDev:(id)dev;
- (void)close;
- (BOOL)isOpen;
- (BOOL)hasMediaType:(NSString *)mediaType;

@end
