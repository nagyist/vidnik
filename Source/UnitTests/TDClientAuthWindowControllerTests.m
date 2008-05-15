//
//  TDClientAuthWindowControllerTests.m
//  Vidnik
//
//  Created by David Oster on 4/3/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <SenTestingKit/SenTestingKit.h>
#import "GDataServiceGoogleYouTube.h"

@interface TDClientAuthWindowControllerTests : SenTestCase {
 @private
  NSTask *server_;
  BOOL isServerRunning_;
  GDataObject *fetchedObject_;
  GDataServiceGoogleYouTube *service_;
  GDataServiceTicket *ticket_;
  NSError *fetcherError_;
  int retryCounter_;
}
- (void)setUp;
- (void)tearDown;
- (void)resetFetchResponse;
@end

static int kServerPortNumber = 54579;

@implementation TDClientAuthWindowControllerTests

- (void)setUp {
  NSBundle *mainBundle = [NSBundle bundleForClass:[self class]];
  NSString *serverPath = [mainBundle pathForResource:@"GDataTestHTTPServer" ofType:@"py"];
  STAssertNotNil(serverPath, @"");

  // Launching the python http server with GC disabled causes it to return an
  // error. To avoid that, we'll change its launch environment to allow the 
  // python server run with GC.
  NSDictionary *env = [[NSProcessInfo processInfo] environment];
  NSMutableDictionary *mutableEnv = [NSMutableDictionary dictionaryWithDictionary:env];
  [mutableEnv removeObjectForKey:@"OBJC_DISABLE_GC"];

  NSArray *argArray = [NSArray arrayWithObjects:serverPath, 
    @"-p", [NSString stringWithFormat:@"%d", kServerPortNumber], 
    @"-r", [serverPath stringByDeletingLastPathComponent], nil];
  
  server_ = [[NSTask alloc] init];
  [server_ setArguments:argArray];
  [server_ setLaunchPath:@"/usr/bin/python"];
  [server_ setEnvironment:mutableEnv];
  
  // pipe will be cleaned up when server_ is torn down.
  NSPipe *pipe = [NSPipe pipe];
  [server_ setStandardOutput:pipe];
  [server_ setStandardError:pipe];
  [server_ launch];
  
  NSData *launchMessageData = [[pipe fileHandleForReading] availableData];
  NSString *launchStr = [[[NSString alloc] initWithData:launchMessageData
                                               encoding:NSUTF8StringEncoding] autorelease];

  
  // our server sends out a string to confirm that it launched;
  // launchStr either has the confirmation, or the error message.
  
  NSString *expectedLaunchStr = @"started GDataTestServer.py...";
  STAssertEqualObjects(launchStr, expectedLaunchStr,
       @">>> Python http test server failed to launch; skipping fetch tests\n"
        "Server path:%@\n", serverPath);
  isServerRunning_ = [launchStr isEqual:expectedLaunchStr];
}

- (void)tearDown {
  [server_ terminate];
  [server_ waitUntilExit];
  [server_ release];
  server_ = nil;
  
  isServerRunning_ = NO;
  
  [service_ release];
  service_ = nil;
  
  [self resetFetchResponse];
}

- (void)resetFetchResponse {
  [fetchedObject_ release];
  fetchedObject_ = nil;
  
  [fetcherError_ release];
  fetcherError_ = nil;
  
  [ticket_ release];
  ticket_ = nil;
  
  retryCounter_ = 0;
}

// turned off for nwo, until we have more significant tests here.
#if 0
- (void)testCaptcha {
  STAssertTrue(isServerRunning_, @"");
}
#endif


@end
