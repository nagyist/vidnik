//
//  Applescript.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/24/08.
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
@interface Applescript : SenTestCase {

}

@end


@implementation Applescript

- (void)testWindowsDocuments {
  NSDictionary *errDict = nil;
  NSString *s = 
// ask the app for a list of windows, ask the app for a list of documents, then get their windows. Should match.
@"tell application \"Vidnik\"\n"
"   (windows = windows of documents)\n"
"end tell\n";
  Boolean valWindow = [[[[[NSAppleScript alloc] initWithSource:s] autorelease] executeAndReturnError:&errDict] booleanValue];

  STAssertTrue(valWindow, @"(windows should = windows of documents)");
  s = 
// ask the app for a list of documents, ask the app for a list of window, then get their documents. Should match.
@"tell application \"Vidnik\"\n"
"   (documents = documents of windows)\n"
"end tell\n";
  Boolean valDocument = [[[[[NSAppleScript alloc] initWithSource:s] autorelease] executeAndReturnError:&errDict] booleanValue];
  STAssertTrue(valDocument, @"(documents should = documents of windows)");

}

@end
