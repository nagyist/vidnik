//
//  Applescript.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/24/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
