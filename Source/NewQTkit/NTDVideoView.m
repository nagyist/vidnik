//
//  TDVideoView.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDVideoView.h"
#import "TDCaptureSession.h"
#import "TDQTKit.h"

@interface TDVideoView(PrivateMethods)
- (void)reinit;
@end
@implementation TDVideoView

- (id)initWithFrame:(NSRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    [self reinit];
  }
  return self;
}

- (void)awakeFromNib {
  [self reinit];
}

- (void)dealloc {
  [mI release];
  [super dealloc];
}

- (void)setCaptureSession:(TDCaptureSession *)captureSession {
  [mI setCaptureSession:[captureSession impl]];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  return NO;
}

@end
@implementation TDVideoView(PrivateMethods)
- (void)reinit {
  [mI release];
  mI = [[QTCaptureView alloc] initWithFrame:[self bounds]];
  [self addSubview:mI];
}
@end

