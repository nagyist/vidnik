//
//  NTDFormatDescription.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
//  Copyright 2008 Google Inc. 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.

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
