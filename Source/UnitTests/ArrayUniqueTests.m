//
//  ArrayUniqueTests.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/20/08.
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

#import <SenTestingKit/SenTestingKit.h>
#import "Array+Unique.h"

@interface ArrayUniqueTests : SenTestCase {
}

@end


@implementation ArrayUniqueTests

- (void)testUnique {
  {
    NSArray *a0 = [NSArray arrayWithObjects: nil];
    NSArray *a1 = [NSArray arrayWithObjects: nil];
    STAssertEqualObjects([a0 unique], a1, @"");
  }
  {
    NSArray *a0 = [NSArray arrayWithObjects: @"Calling", @"a", @"A", @"b", @"B", nil];
    NSArray *a1 = [NSArray arrayWithObjects: @"Calling", @"a", @"b", nil];
    STAssertEqualObjects([a0 unique], a1, @"");
  }
  {
    NSArray *a0 = [NSArray arrayWithObjects: @"A", @"a", @"A", @"B", @"b", @"B", @"Calling", nil];
    NSArray *a1 = [NSArray arrayWithObjects: @"A", @"B", @"Calling", nil];
    STAssertEqualObjects([a0 unique], a1, @"");
  }
}


@end
