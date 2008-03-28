//
//  ArrayUniqueTests.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/20/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
