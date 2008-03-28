//
//  StringFormatTests.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/20/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <SenTestingKit/SenTestingKit.h>
#import "StringFormat.h"

@interface StringFormatTests : SenTestCase {
}

@end


@implementation StringFormatTests

- (void)testStringFromFileSize {
  {
    NSString *a0 = [NSString stringFromFileSize:100];
    NSString *a1 = @"100B";
    STAssertEqualObjects(a0, a1, @"");

    NSString *b0 = [NSString stringFromFileSize:10000];
    NSString *b1 = @"10K";
    STAssertEqualObjects(b0, b1, @"");

    NSString *c0 = [NSString stringFromFileSize:1000000];
    NSString *c1 = @"1M";
    STAssertEqualObjects(c0, c1, @"");

    NSString *d0 = [NSString stringFromFileSize:100000000];
    NSString *d1 = @"100M";
    STAssertEqualObjects(d0, d1, @"");
  }

  {
    NSString *a0 = [NSString stringFromFileSize:900];
    NSString *a1 = @"900B";
    STAssertEqualObjects(a0, a1, @"");

    NSString *b0 = [NSString stringFromFileSize:90000];
    NSString *b1 = @"90K";
    STAssertEqualObjects(b0, b1, @"");

    NSString *c0 = [NSString stringFromFileSize:9000000];
    NSString *c1 = @"9M";
    STAssertEqualObjects(c0, c1, @"");

    NSString *d0 = [NSString stringFromFileSize:900000000];
    NSString *d1 = @"900M";
    STAssertEqualObjects(d0, d1, @"");
  }
}

- (void)testStringFromTime {

  NSString *a0 = [NSString stringFromTime:1.1];
  NSString *a1 = @"00:00:01.1";
  STAssertEqualObjects(a0, a1, @"");

  NSString *b0 = [NSString stringFromTime:100.1];
  NSString *b1 = @"00:01:40.1";
  STAssertEqualObjects(b0, b1, @"");

  NSString *c0 = [NSString stringFromTime:1000.1];
  NSString *c1 = @"00:16:40.1";
  STAssertEqualObjects(c0, c1, @"");

  NSString *d0 = [NSString stringFromTime:10000.1];
  NSString *d1 = @"02:46:40.1";
  STAssertEqualObjects(d0, d1, @"");
}

@end
