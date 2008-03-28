//
//  String+PathTests.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/20/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <SenTestingKit/SenTestingKit.h>
#import "String+Path.h"

@interface StringPathTests : SenTestCase {
}

@end

// convenience character set builder
static NSCharacterSet *CS(NSString *s) {
  return [NSCharacterSet characterSetWithCharactersInString:s];
}

// convenience array builder
static NSArray *A1(NSString *a) {
  return [NSArray arrayWithObjects:a, nil];
}

static NSArray *A2(NSString *a, NSString *b) {
  return [NSArray arrayWithObjects:a, b, nil];
}

static NSArray *A3(NSString *a, NSString *b, NSString *c) {
  return [NSArray arrayWithObjects:a, b, c, nil];
}

@implementation StringPathTests


- (void)testStringByReplacingString {
  STAssertEqualObjects([@"abc abc" stringByReplacingString:nil withString:nil], @"abc abc", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:nil withString:@"B"], @"abc abc", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:@"" withString:@"B"], @"abc abc", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:@"b" withString:@"Boy"], @"aBoyc aBoyc", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:@"a" withString:@"Boy"], @"Boybc Boybc", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:@"A" withString:@"Boy"], @"abc abc", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:@"c" withString:@"Boy"], @"abBoy abBoy", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:@"abc" withString:@"Boy"], @"Boy Boy", @"");
  STAssertEqualObjects([@"abc abc" stringByReplacingString:@"abc abc" withString:@"Boy"], @"Boy", @"");
}

- (void)testComponentsSeparatedByCharacterSet {
  {
    NSArray *val = A1(@"abc abc");
    STAssertEqualObjects([@"abc abc" componentsSeparatedByCharacterSet:nil ], val, @"");
  }
  {
    NSArray *val = A1(@"abc abc");
    STAssertEqualObjects([@"abc abc" componentsSeparatedByCharacterSet:CS(@"") ], val, @"");
  }
  {
    NSArray *val = A3(@"a", @"c a", @"c");
    STAssertEqualObjects([@"abc abc" componentsSeparatedByCharacterSet:CS(@"b") ], val, @"");
  }
  {
    NSArray *val = A2(@"bc ", @"bc");
    STAssertEqualObjects([@"abc abc" componentsSeparatedByCharacterSet:CS(@"a") ], val, @"");
  }
  {
    NSArray *val = A1(@"abc abc");
    STAssertEqualObjects([@"abc abc" componentsSeparatedByCharacterSet:CS(@"A") ], val, @"");
  }
  {
    NSArray *val = A2(@"ab", @" ab");
    STAssertEqualObjects([@"abc abc" componentsSeparatedByCharacterSet:CS(@"c") ], val, @"");
  }
  {
    NSArray *val = A1(@" ");
    STAssertEqualObjects([@"abc abc" componentsSeparatedByCharacterSet:CS(@"abc") ], val, @"");
  }
}

@end
