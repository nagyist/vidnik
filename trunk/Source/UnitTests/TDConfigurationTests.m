//
//  TDConfigurationTests.m
//  VideoRecorder
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
#import "TDConfiguration.h"
#import "TDAppController.h"

@interface MockNSUserDefaults : NSObject {
  NSMutableDictionary *mDict;
}

- (id)objectForKey:(NSString *)key;
- (NSString *)stringForKey:(NSString *)key;
- (void)setObject:(id)object forKey:(NSString *)key;
@end

@implementation MockNSUserDefaults
- (id)init {
  self = [super init];
  if (self) {
    mDict = [[NSMutableDictionary alloc] init];
  }
  return self;
}

- (void)dealloc {
  [mDict release];
  [super dealloc];
}
- (id)objectForKey:(NSString *)key {
  return [mDict objectForKey:key];
}

- (NSString *)stringForKey:(NSString *)key {
  return (NSString *)[self objectForKey:key];
}

- (void)setObject:(id)object forKey:(NSString *)key {
  [mDict setObject:object forKey:key];
}

- (void)synchronize {
}
@end

@interface TDConfigurationTests : SenTestCase {
 @private
  TDConfiguration *mSaveConfig;
}
- (void)setUp;
- (void)tearDown;
@end


@implementation TDConfigurationTests

- (void)setUp {
  mSaveConfig = [[(TDAppController *)[NSApp delegate] config] retain];
  [(TDAppController *)[NSApp delegate] setConfig:[[[[mSaveConfig class] alloc] init] autorelease]];
  [[(TDAppController *)[NSApp delegate] config] setUserDefaults:(NSUserDefaults *)[[[MockNSUserDefaults alloc] init] autorelease]];
}

- (void)tearDown {
  [[(TDAppController *)[NSApp delegate] config] setUserDefaults:nil];
  [(TDAppController *)[NSApp delegate] setConfig:mSaveConfig];
  [mSaveConfig autorelease];
  mSaveConfig = nil;
}


- (void)testCategories {
  TDConfiguration *conf = [(TDAppController *)[NSApp delegate] config];
  STAssertNil([conf categories], @"");
  [conf setCategories:[NSArray arrayWithObjects: 
    [NSArray arrayWithObjects:@"alpha", @"a", nil],
    [NSArray arrayWithObjects:@"beta", @"b", nil],
    [NSArray arrayWithObjects:@"gamma", @"c", nil],
   nil]];
  NSArray *test = [NSArray arrayWithObjects: 
    [NSArray arrayWithObjects:@"alpha", @"a", nil],
    [NSArray arrayWithObjects:@"beta", @"b", nil],
    [NSArray arrayWithObjects:@"gamma", @"c", nil],
   nil];
  STAssertEqualObjects([conf categories], test, @"");
}

- (void)testCategoriesFetchDate {
  TDConfiguration *conf = [(TDAppController *)[NSApp delegate] config];
  STAssertNil([conf categoriesFetchDate], @"");
  NSDate *date = [NSDate date];
  [conf setCategoriesFetchDate:date];
  STAssertEqualObjects([conf categoriesFetchDate], date, @"");
}

- (void)testCurrentCategory {
  TDConfiguration *conf = [(TDAppController *)[NSApp delegate] config];
  STAssertEqualObjects([conf defaultCategoryTerm], @"People", @"");
}


@end
