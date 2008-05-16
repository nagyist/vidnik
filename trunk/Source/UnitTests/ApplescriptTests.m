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
// ask the app for a list of windows, ask the app for a list of documents, then get their windows. Should match.
  NSString *s = 
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


- (void)testMakeAndDelete {
  NSDictionary *errDict = nil;
// create 3 movies. verify that the count is 3 greater than before. delete them.
// verify that the count is back to the original count.
  NSString *s = 
@"tell application \"Vidnik\"\n"
"	set originalCount to count of movies of document 1\n"
"	\n"
"	set aa to (make new movie at end of document 1 with properties {name:\"testMakeAndDelete 1\"})\n"
"	set bb to (make new movie at end of document 1 with properties {name:\"testMakeAndDelete 2\"})\n"
"	set cc to (make new movie at end of document 1 with properties {name:\"testMakeAndDelete 3\"})\n"
"	\n"
"	set plusCount to count of movies of document 1\n"
"	\n"
"	delete last movie of document 1\n"
"	delete aa\n"
"	delete bb\n"
"	\n"
"	(plusCount - originalCount) = 3 and (count of movies of document 1) = originalCount\n"
"end tell\n";
  Boolean val = [[[[[NSAppleScript alloc] initWithSource:s] autorelease] executeAndReturnError:&errDict] booleanValue];

  STAssertTrue(val, @"testMakeAndDelete");

}

- (void)testMove {
  NSDictionary *errDict = nil;
// create 3 movies. move last to before first.
// verify new index is as expected.
  NSString *s = 
@"tell application \"Vidnik\"\n"
"	set aa to (make new movie at end of document 1 with properties {name:\"testMove 1\"})\n"
"	set bb to (make new movie at end of document 1 with properties {name:\"testMove 2\"})\n"
"	set cc to (make new movie at end of document 1 with properties {name:\"testMove 3\"})\n"

"	set aaIndex to index of aa\n"
"	move cc to before aa\n"
"	set ccIndex to index of cc\n"
"	set aaNewIndex to index of aa\n"

"	delete aa\n"
"	delete bb\n"
"	delete cc\n"
"	\n"
"	(aaIndex = ccIndex) and (aaIndex + 1 = aaNewIndex)\n"
"end tell\n";
  Boolean val = [[[[[NSAppleScript alloc] initWithSource:s] autorelease] executeAndReturnError:&errDict] booleanValue];

  STAssertTrue(val, @"testMove");
}

@end
