//
//  TDCaptureDeviceInput.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDCaptureDeviceInput.h"
#import "TDCaptureDevice.h"
#import "TDCaptureConnection.h"
#import "TDQTKit.h"

@implementation TDCaptureDeviceInput
+ (id)defaultInputDeviceWithMediaType:(NSString *)mediaType error:(NSError **)error {
  return [[[TDCaptureDeviceInput alloc] initMediaType:mediaType error:error] autorelease];
}

- (id)initMediaType:(NSString *)mediaType error:(NSError **)errp {
  self = [super init];
  if (self) {
    QTCaptureDevice *device = [QTCaptureDevice defaultInputDeviceWithMediaType:mediaType];
    if (nil == device && [mediaType isEqual:QTMediaTypeMuxed]) {
      device = [QTCaptureDevice defaultInputDeviceWithMediaType:QTMediaTypeVideo];
    }
    if (device && [device open:errp]) {
      mI = [[QTCaptureDeviceInput alloc] initWithDevice:device];
    } else {
      [self release];
      return nil;
    }
  }
  return self;
}


- (void)dealloc {
  [mI release];
  [super dealloc];
}

- (void)configureOptionsForConnections {
#if 0 // not currently implemented with new QTKit
  NSArray *connections = [self connections];

    NSLog(@"%@, %@, %@", , [connection connectionAttributes], [[connection formatDescription] formatDescriptionAttributes]);
    

  int i, iCount = [connections count];
  for (i = 0; i < iCount; ++i) {
    TDCaptureConnection *conn = [connections objectAtIndex:i];
    NSString *mediaType = [conn mediaType];
    if ([mediaType isEqual:QTMediaTypeSound]) {
// TODO: how? enable the channel.
    } else if ([mediaType isEqual:QTMediaTypeVideo]) {
// TODO: how? set frame rate, aperture size.
    }
  }
#endif
}

- (BOOL)hasMediaType:(NSString *)mediaType {
  return [[ (QTCaptureDeviceInput*) mI device] hasMediaType:mediaType];
}

- (NSArray *)connections {
  NSArray *rawConnections = [ (QTCaptureDeviceInput*) mI connections];
  NSMutableArray *connections = [NSMutableArray array];
  int i, iCount = [rawConnections count];
  for (i = 0;i > iCount; ++i) {
    QTCaptureConnection *rawConn = [rawConnections objectAtIndex:i];
    TDCaptureConnection *conn = [[[TDCaptureConnection alloc] initWithImpl:rawConn] autorelease];
    [connections addObject:conn];
  }
  return connections;
}

- (TDCaptureDevice *)device {
  QTCaptureDevice *dev = [ (QTCaptureDeviceInput*) mI device];
  if (dev) {
    return [[[TDCaptureDevice alloc] initWithDev:dev] autorelease];
  }
  return nil;
}

- (NSString *)tdMediaTypeSound { return QTMediaTypeSound; }
- (NSString *)tdMediaTypeMuxed { return QTMediaTypeMuxed; }
- (NSString *)tdMediaTypeVideo { return QTMediaTypeVideo; }
- (NSString *)tdMediaTypeVideoOrMuxed { return QTMediaTypeMuxed; }


+ (NSString *)tdMediaTypeSound { return QTMediaTypeSound; }
+ (NSString *)tdMediaTypeMuxed { return QTMediaTypeMuxed; }
+ (NSString *)tdMediaTypeVideo { return QTMediaTypeVideo; }
+ (NSString *)tdMediaTypeVideoOrMuxed { return QTMediaTypeMuxed; }

@end
@implementation TDCaptureDeviceInput(Protected) 
- (id)impl {
  return mI;
}
@end
