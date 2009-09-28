//
//  UploadTests.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 3/20/08.
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
#import "TDiaryDocument.h"
#import "TDPlaylistAdditions.h"
#import "TDPlaylistController.h"
#import "GDataServiceGoogleYouTube.h"
#import "GDataEntryYouTubeUpload.h"
#import "GDataProgressMonitorInputStream.h"
#import "ProgressCell.h"
#import <OCMock/OCMockObject.h>
#import <OCMock/OCMockRecorder.h>

@class MockService;

@interface MockTicket : NSObject {
  MockService *mService;
  BOOL mHasCalledCallback;
  id    mUserData;
}
- (id)initWithService:(MockService *)service;
- (id)userData;
- (void)setUserData:(id)userData;
- (BOOL)hasCalledCallback;
- (void)setHasCalledCallback:(BOOL)hasCalledCallback;
@end

@interface MockService : NSObject {
  SenTestCase *mTest;
  MockTicket *mTicket;
  NSTimer *mTimer;
  id mDelegate;
  id mUserData;
  SEL mProgressSel;
  SEL mFinishedSel;
  BOOL mWillSucceed;
  float mProgress;
}
- (NSString *)password;
- (NSString *)username;
- (id)serviceUserData;
- (void)setServiceUserData:(id)userData;
- (void)setUserCredentialsWithUsername:(NSString *)username password:(NSString *)password;
@end


@implementation MockTicket
- (id)initWithService:(MockService *)service {
  self = [super init];
  if (self) {
    mService = service;
  }
  return self;
}

- (void)dealloc {
  [mUserData release];
  [super dealloc];
}

- (id)userData {
  return mUserData;
}

- (void)setUserData:(id)userData {
  [mUserData autorelease];
  mUserData = [userData retain];
}

- (BOOL)hasCalledCallback {
  return mHasCalledCallback;
}

- (void)setHasCalledCallback:(BOOL)hasCalledCallback {
  mHasCalledCallback = hasCalledCallback;
}


@end


@implementation MockService
- (id)initWithTest:(SenTestCase *)test {
  self = [super init];
  if (self) {
    mTest = [test retain];
    mTicket = [(MockTicket*)[MockTicket alloc] initWithService:self];
  }
  return self;
}

- (void)dealloc {
  [mTimer invalidate];
  [mTimer release];
  mTimer = nil;
  [mUserData release];
  [mTest release];
  [mTicket release];
  [super dealloc];
}

- (id)serviceUserData {
  return mUserData;
}

- (void)setServiceUserData:(id)userData {
  [mUserData autorelease];
  mUserData = [userData retain];
}


- (void)setWillSucceed:(BOOL)didSucceed {
  mWillSucceed = didSucceed;
}

- (NSString *)password {
  return @"MockServicePassword";
}

- (NSString *)username {
  return @"MockServiceUsername";
}

- (MockTicket *)ticket {
  return mTicket;
}

- (void)setUserCredentialsWithUsername:(NSString *)username password:(NSString *)password {
}

- (void)setServiceUploadProgressSelector:(SEL)progressSelector {
  mProgressSel = progressSelector;
}

- (GDataServiceTicket *)fetchEntryByInsertingEntry:(GDataEntryBase *)entryToInsert
                                               forFeedURL:(NSURL *)youTubeFeedURL
                                                 delegate:(id)delegate
                                        didFinishSelector:(SEL)finishedSelector {
	mDelegate = delegate;
  mFinishedSel = finishedSelector;
  mTimer = [[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES] retain];
  [mTicket setUserData:[self serviceUserData]];
  return (GDataServiceTicket *) mTicket;
}

- (void)timerFired:(NSTimer *)timer {
  mProgress += 0.03;
  if (1. <= mProgress) {
    mProgress = 1.;
    [mTimer invalidate];
    [mTimer release];
    mTimer = nil;
    if (mWillSucceed) {
      id mockLink = [OCMockObject mockForClass:[GDataLink class]];
      [[[mockLink stub] andReturn:@"http://youtube.com/mockUpload"] href];

      id mockLinks = [OCMockObject mockForClass:[NSArray class]];
      [[[mockLinks stub] andReturn:mockLink] alternateLink];

      id mockUpload = [OCMockObject mockForClass:[GDataEntryYouTubeUpload class]];
      [[[mockUpload stub] andReturn:mockLinks] links];

      objc_msgSend(mDelegate, mFinishedSel, mTicket, mockUpload, nil);
    }else {
      NSError *err = [NSError errorWithDomain:@"MockUpload" code:404 userInfo:nil];
      objc_msgSend(mDelegate, mFinishedSel, mTicket, nil, err);
    }
    [mTicket setHasCalledCallback:YES];
    [mTicket autorelease];
    mTicket = [(MockTicket*)[MockTicket alloc] initWithService:self];
  } else {
    id mockStream = [OCMockObject mockForClass:[GDataProgressMonitorInputStream class]];
    [[[mockStream stub] andReturn:mTicket] monitorSource];
    unsigned long long soFar =  (mProgress*1.14*10000);
    if (10000ULL < soFar) {
      soFar = 10000;
    }
    objc_msgSend(mDelegate, mProgressSel, mockStream, soFar, 10000ULL);
  }
}

@end

@interface FastClock : NSObject
- (NSTimeInterval)timeIntervalSinceReferenceDate;
@end
@implementation FastClock
// so progress meter treats seconds as if they were minutes
- (NSTimeInterval)timeIntervalSinceReferenceDate {
  return [NSDate timeIntervalSinceReferenceDate] * 60.;
}
@end

// for test first development that the progress meters for bulk upload are
// reasonable.

@interface UploadTests : SenTestCase {
  MockService *mService;
  TDiaryDocument *mDocument;
  GDataServiceGoogleYouTube *mSavedService;
}

@end


@implementation UploadTests

- (void)setUp {
  [ProgressCell setTimeIntervalSource:[[[FastClock alloc] init] autorelease]];
  NSArray *documents = [[NSDocumentController sharedDocumentController] documents];
  mDocument = [[documents objectAtIndex:0] retain];
  [mDocument setSuppressingErrorDialog:YES];
  mSavedService = [[mDocument service] retain];
}

- (void)tearDown {
  [ProgressCell setTimeIntervalSource:nil];
  [mService release];
  mService = nil;
  [mDocument setService:mSavedService];
  [mDocument setSuppressingErrorDialog:NO];
  [mSavedService release];
  [mDocument release];
}

- (void)runUntilDone {
  NSDate* giveUpDate = [NSDate dateWithTimeIntervalSinceNow:10];
  MockTicket *ticket = [[mService ticket] retain];
  
  while ( ! [ticket hasCalledCallback] && 0 < [giveUpDate timeIntervalSinceNow]) {
    NSDate *stopDate = [NSDate dateWithTimeIntervalSinceNow:0.001];
    [[NSRunLoop currentRunLoop] runUntilDate:stopDate]; 
  }
  [ticket release];
}

- (void)testUploadSucceed {
  mService = [[MockService alloc] initWithTest:self];
  [mService setWillSucceed:YES];
  [mDocument setService:(GDataServiceGoogleYouTube *)mService];
  NSArray *ready = [[mDocument playlist] moviesReadyToUpload];
  [[mDocument playlistController] upload:nil];
  for (int i = 0; i < [ready count]; ++i) {
    [self runUntilDone];
  }
}

- (void)testUploadFail {
  mService = [[MockService alloc] initWithTest:self];
  [mService setWillSucceed:NO];
  [mDocument setService:(GDataServiceGoogleYouTube *)mService];
  [[mDocument playlistController] upload:nil];
  [self runUntilDone];
}

@end
