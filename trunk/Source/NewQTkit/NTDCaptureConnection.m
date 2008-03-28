//
//  TDCaptureConnection.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDCaptureConnection.h"
#import "TDFormatDescription.h"
#import "TDQTKit.h"

@implementation TDCaptureConnection

- (id)initWithImpl:(id)impl {
  self = [super init];
  if (self) {
    mI = [impl retain];
  }
  return self;
}


- (void)dealloc {
  [mI release];
  [super dealloc];
}

- (id)attributeForKey:(NSString *)key {
  return [mI attributeForKey:key];
}

- (void)setAttribute:(id)property forKey:(NSString *)attributeKey {
  [mI setAttribute:property forKey:attributeKey];
}

- (BOOL)attributeIsReadOnly:(NSString *)attributeKey {
  return [mI attributeIsReadOnly:attributeKey];
}

- (NSDictionary *)connectionAttributes {
  return [mI connectionAttributes];
}

- (void)setConnectionAttributes:(NSDictionary *)connectionAttributes {
  [mI setConnectionAttributes:connectionAttributes];
}

- (TDFormatDescription *)formatDescription {
  QTFormatDescription *rawDesc = [(QTCaptureConnection *)mI formatDescription];
  if (nil == rawDesc) {
    return nil;
  }
  return [[[TDFormatDescription alloc] initWithImpl:rawDesc] autorelease];
}

- (BOOL)isEnabled {
  return [mI isEnabled];
}

- (void)setEnabled:(BOOL)isEnabled {
  [mI setEnabled:isEnabled];
}

- (NSString *)mediaType {
  return [mI mediaType];
}



@end
