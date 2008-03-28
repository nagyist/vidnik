//
//  TDCaptureDeviceInput.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

@class TDCaptureDevice;

// Wrap OS X 10.5 only QTKit class QTCaptureDeviceInput, 
// so we can re-implement for Tiger
@interface TDCaptureDeviceInput : NSObject {
 @private
  id mI;  // implementation
}

+ (id)defaultInputDeviceWithMediaType:(NSString *)mediaType error:(NSError **)error;
- (id)initMediaType:(NSString *)mediaType error:(NSError **)errp;
- (TDCaptureDevice *)device;
- (BOOL)hasMediaType:(NSString *)mediaType;
- (NSArray *)connections;
- (void)configureOptionsForConnections;

+ (NSString *)tdMediaTypeSound;
- (NSString *)tdMediaTypeSound;
+ (NSString *)tdMediaTypeMuxed;
- (NSString *)tdMediaTypeMuxed;
+ (NSString *)tdMediaTypeVideo;
- (NSString *)tdMediaTypeVideo;
+ (NSString *)tdMediaTypeVideoOrMuxed;
- (NSString *)tdMediaTypeVideoOrMuxed;

@end
@interface TDCaptureDeviceInput(Protected) 
- (id)impl;
@end

extern Class gTDCaptureDeviceInput;

#define TDMediaTypeSound  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeSound]
#define TDMediaTypeMuxed  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeMuxed]
#define TDMediaTypeVideo  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeVideo]
#define TDMediaTypeVideoOrMuxed  [(TDCaptureDeviceInput *)gTDCaptureDeviceInput tdMediaTypeVideoOrMuxed]
