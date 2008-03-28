//
//  NTDFormatDescription.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDFormatDescription.h"
#import "TDQTKit.h"


@implementation TDFormatDescription
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

- (NSString *)mediaType {
  return [mI mediaType];
}

- (UInt32)formatType {
  return [mI formatType];
}

- (NSString *)localizedFormatSummary {
  return [mI localizedFormatSummary];
}

- (NSDictionary *)formatDescriptionAttributes {
  return [mI formatDescriptionAttributes];
}

- (id)attributeForKey:(NSString *)key {
  return [mI attributeForKey:key];
}


@end
