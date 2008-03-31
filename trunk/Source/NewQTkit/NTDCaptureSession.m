//
//  TDCaptureSession.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDCaptureSession.h"
#import "TDCaptureMovieFileOutput.h"
#import "TDQTKit.h"

Class gTDCaptureSession;

@implementation TDCaptureSession

- (id)init {
  self = [super init];
  if (self) {
    mI = [[QTCaptureSession alloc] init];
    if (nil == mI) {
      [self release];
      return nil;
    }
    NSNotificationCenter *nc =[NSNotificationCenter defaultCenter];
    [nc addObserver:self
      selector:@selector(sessionRuntimeError:) 
          name:QTCaptureSessionRuntimeErrorNotification 
         object:nil];
  }
  return self;
}

- (void)dealloc {
  NSNotificationCenter *nc =[NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  [mI release];
  [super dealloc];
}

- (BOOL)addInput:(TDCaptureDeviceInput *)inDev error:(NSError **)error {
  return [mI addInput:[inDev impl] error:error];
}

- (BOOL)addOutput:(TDCaptureMovieFileOutput *)outFile error:(NSError **)error {
  return [mI addOutput:[outFile impl] error:error];
}

- (TDCaptureMovieFileOutput *)captureFileOutput {
  TDCaptureMovieFileOutput *captureFileOutput = nil;
  NSArray *outputs = [mI outputs];
  int i, iCount = [outputs count];
  for (i = 0; i < iCount; ++i) {
    QTCaptureFileOutput *out = [outputs objectAtIndex:i];
    if ([[out class] isEqual:[QTCaptureMovieFileOutput class]]) {
      captureFileOutput = [[[TDCaptureMovieFileOutput alloc] initWithImpl:out] autorelease];
      break;
    }
  }
  return captureFileOutput;
}


- (BOOL)isRunning {
  return [mI isRunning];
}

- (void)startRunning {
  // will crash if there isn't any input.
  if ([[mI inputs] count]) {
    [mI startRunning];
  }
}

- (void)stopRunning {
  [mI stopRunning];
}


- (float)masterRecordVolume {
  float masterRecordVolume = 0.0;
  NSArray *outputs = [mI outputs];
  int i, iCount = [outputs count];
  for (i = 0; i < iCount; ++i) {
    QTCaptureFileOutput *out = [outputs objectAtIndex:i];
    if ( ! [[out class] isEqual:[QTCaptureAudioPreviewOutput class]]) {
      NSArray *connections = [out connections];
      int j, jCount = [connections count];
      for (j = 0; j < jCount; ++j) {
        QTCaptureConnection *conn = [connections objectAtIndex:j];
        NSString *mediaType = [conn mediaType];
        if ([mediaType isEqualToString:QTMediaTypeSound] ||
            [mediaType isEqualToString:QTMediaTypeMuxed]) {
          NSNumber *channelVolumeN = [conn attributeForKey:QTCaptureConnectionAudioMasterVolumeAttribute];
          if (channelVolumeN) {
            float channelVolume = [channelVolumeN floatValue];
            if (masterRecordVolume < channelVolume) {
              masterRecordVolume = channelVolume;
            }
          }
        }
      }
    }
  }
  return masterRecordVolume;
}

- (void)setMasterRecordVolume:(float)masterRecordVolume {
  NSNumber *channelVolumeN = [NSNumber numberWithFloat:masterRecordVolume];
  NSArray *outputs = [mI outputs];
  int i, iCount = [outputs count];
  for (i = 0; i < iCount; ++i) {
    QTCaptureFileOutput *out = [outputs objectAtIndex:i];
    if ( ! [[out class] isEqual:[QTCaptureAudioPreviewOutput class]]) {
      NSArray *connections = [out connections];
      int j, jCount = [connections count];
      for (j = 0; j < jCount; ++j) {
        QTCaptureConnection *conn = [connections objectAtIndex:j];
        NSString *mediaType = [conn mediaType];
        if ([mediaType isEqualToString:QTMediaTypeSound] ||
            [mediaType isEqualToString:QTMediaTypeMuxed]) {
          [conn setAttribute:channelVolumeN forKey:QTCaptureConnectionAudioMasterVolumeAttribute];
        }
      }
    }
  }
}

- (float)audioPowerLevel {
  float audioPowerLevel = -1000000.0;
  NSArray *outputs = [mI outputs];
  int i, iCount = [outputs count];
  for (i = 0; i < iCount; ++i) {
    QTCaptureFileOutput *out = [outputs objectAtIndex:i];
    if ( ! [[out class] isEqual:[QTCaptureAudioPreviewOutput class]]) {
      NSArray *connections = [out connections];
      int j, jCount = [connections count];
      for (j = 0; j < jCount; ++j) {
        QTCaptureConnection *conn = [connections objectAtIndex:j];
        NSString *mediaType = [conn mediaType];
        if ([mediaType isEqualToString:QTMediaTypeSound] ||
            [mediaType isEqualToString:QTMediaTypeMuxed]) {
          NSArray *powerLevels = [conn attributeForKey:QTCaptureConnectionAudioAveragePowerLevelsAttribute];
          int k, powerLevelCount = [powerLevels count];
          for (k = 0; k < powerLevelCount; k++) {
            NSNumber *decibelsN = [powerLevels objectAtIndex:k];
            if (decibelsN) {
              float decibels = [decibelsN floatValue];
              if (audioPowerLevel < decibels) {
                audioPowerLevel = decibels;
              }
            }
          }
        }
      }
    }
  }
  return audioPowerLevel;
}


// I originally had this code in TDCaptureMovieFileOutput, but it wasn't
// confiuring anything. Asking the session for the output does work, though.
- (void)configureOutputs {
//	QTCaptureAudioPreviewOutput *audioPreviewOutput = [[QTCaptureAudioPreviewOutput alloc] init];
//	[audioPreviewOutput setVolume:0.0];
//	[(QTCaptureSession *)mI addOutput:audioPreviewOutput error:nil];	

  BOOL didSome = NO;
  QTCompressionOptions *soundOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptionsVoiceQualityAACAudio"];
  QTCompressionOptions *videoOptions = [QTCompressionOptions compressionOptionsWithIdentifier:@"QTCompressionOptions480SizeMPEG4Video"];
  NSArray *outputs = [mI outputs];
  int i, iCount = [outputs count];
  for (i = 0; i < iCount; ++i) {
    QTCaptureFileOutput *out = [outputs objectAtIndex:i];
    if ([out respondsToSelector:@selector(setCompressionOptions:forConnection:)]) {
      NSArray *connections = [out connections];
      int j, jCount = [connections count];
      for (j = 0; j < jCount; ++j) {
        QTCaptureConnection *conn = [connections objectAtIndex:j];
        NSString *mediaType = [conn mediaType];
        if ([mediaType isEqual:QTMediaTypeSound]) {
          if (soundOptions) {
            [out setCompressionOptions:soundOptions forConnection:conn];
            didSome = YES;
          }
        } else if ([mediaType isEqual:QTMediaTypeVideo]) {
          if (videoOptions) {
            [out setCompressionOptions:videoOptions forConnection:conn];
            didSome = YES;
          }
        }
      }
    }
  }
  if (!didSome) {
    fprintf(stderr, "warning: [TDCaptureSession configureOutputs] did not configure any outputs.\n");
  }
}


- (void)sessionRuntimeError:(NSNotification *)n {
  NSNotificationCenter *nc =[NSNotificationCenter defaultCenter];
  NSDictionary *rawInfo = [n userInfo];
  NSDictionary *info = nil;
  id err = [rawInfo objectForKey:QTCaptureSessionErrorKey];
  if (err) {
    info = [NSDictionary dictionaryWithObjectsAndKeys:
      err, [self runtimeErrorKey], nil];
  }
  [nc postNotificationName:[self runtimeErrorNotification]
                    object:[n object] 
                  userInfo:info];
}

+ (NSString *)runtimeErrorNotification {
  return @"TDCaptureSessionRuntimeErrorNotification";
}

- (NSString *)runtimeErrorNotification {
  return @"TDCaptureSessionRuntimeErrorNotification";
}

+ (NSString *)runtimeErrorKey {
  return QTCaptureSessionErrorKey;
}

- (NSString *)runtimeErrorKey {
  return QTCaptureSessionErrorKey;
}



@end
@implementation TDCaptureSession(Protected) 
- (id)impl {
  return mI;
}
@end


