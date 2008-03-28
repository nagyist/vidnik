//
//  TDCaptureDevice.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
