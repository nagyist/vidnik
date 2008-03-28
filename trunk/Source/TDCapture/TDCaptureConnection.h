//
//  TDCaptureConnection.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

@class TDFormatDescription;

// Wrap OS X 10.5 only QTKit class QTCaptureConnection, 
// so we can re-implement for Tiger
@interface TDCaptureConnection : NSObject {
 @private
  id mI;  // implementation
}

- (id)attributeForKey:(NSString *)key;
- (void)setAttribute:(id)property forKey:(NSString *)attributeKey;
- (BOOL)attributeIsReadOnly:(NSString *)attributeKey;
- (NSDictionary *)connectionAttributes;
- (void)setConnectionAttributes:(NSDictionary *)connectionAttributes;
- (TDFormatDescription *)formatDescription;
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)isEnabled;
- (NSString *)mediaType;


- (id)initWithImpl:(id)impl;
@end
