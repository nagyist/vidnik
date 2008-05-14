//
//  TDConfiguration.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
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

#import "TDConfiguration.h"
#import "TDConstants.h"
#import "TDAppController.h"
#import "String+Path.h"
#import "DeveloperKey.h"

static NSString * const kAppID = @"appID";
static NSString * const kCategoriesKey = @"categories";
static NSString * const kCategoriesFetchDateKey = @"categoriesFetchDate";
static NSString * const kDefaultCategoryTermKey = @"defaultCategoryTerm";

// preference key: don't fill the disk beyond this point.
static NSString * const kDiskFreeSpaceKey = @"freeSpace";

static NSString * const kLastDocumentPath = @"lastDocumentPath";
static NSString * const kLastDocumentID = @"lastDocumentID";

static NSString * const kMaxMovieSize = @"maxMovieSize";
static NSString * const kMaxMovieDuration = @"maxMovieDuration";

// preference key: path, with tilde, of the folder where Vidnik writes movies
static NSString * const kMovieFolderKey = @"movieFolder";




#if MAC_OS_X_VERSION_MIN_REQUIRED >= 1050

static id TDMakeCollectable(CFTypeRef cf) { 
  return NSMakeCollectable(cf); 
}

#else

static id TDMakeCollectable(CFTypeRef cf) { 
  // NSMakeCollectable handles NULLs just fine and returns nil as expected.
  return (id)cf;
}

#endif


static NSUserDefaults *gUD = nil;

NSString *NewUUID(void) {
  CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
  NSString *identifier = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
  CFRelease(uuid);
  return [TDMakeCollectable(identifier) autorelease];
}

@interface TDConfiguration(PrivateMethods)
- (NSUserDefaults *)userDefaults;
@end
@implementation TDConfiguration
// for unit testing: allows passing in a mock.
- (void)setUserDefaults:(NSUserDefaults *)userDefaults {
  [gUD autorelease];
  gUD = [userDefaults retain];
}

- (void)synchronize {
  NSUserDefaults *ud = [self userDefaults];
  [ud synchronize];
}

- (NSArray *)categories {  // of arrays of label, term strings
  NSUserDefaults *ud = [self userDefaults];
  return [ud objectForKey:kCategoriesKey];
}

- (void)setCategories:(NSArray *)categories {
  NSUserDefaults *ud = [self userDefaults];
  NSArray *oldCategories = [self categories];
  if (nil == oldCategories || ! [categories isEqual:oldCategories]) {
    if (categories) {
      NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
      [nc postNotificationName:kCategoriesWillChange object:oldCategories];
      [ud setObject:categories forKey:kCategoriesKey];
      [nc postNotificationName:kCategoriesDidChange object:categories];
    }
  }
}


- (NSDate *)categoriesFetchDate {
  NSUserDefaults *ud = [self userDefaults];
  return [ud objectForKey:kCategoriesFetchDateKey];
}

- (void)setCategoriesFetchDate:(NSDate *)date {
  NSUserDefaults *ud = [self userDefaults];
  if (date) {
    [ud setObject:date forKey:kCategoriesFetchDateKey];
  } else {
    [ud removeObjectForKey:kCategoriesFetchDateKey];
  }
}

- (NSString *)defaultCategoryTerm {
  NSUserDefaults *ud = [self userDefaults];
  NSString *val = [ud stringForKey:kDefaultCategoryTermKey];
  if (nil == val) {
    val = @"People";
  }
  return val;
}

- (void)setDefaultCategoryTerm:(NSString *)defaultCategoryTerm {
  NSUserDefaults *ud = [self userDefaults];
  if (defaultCategoryTerm) {
    [ud setObject:defaultCategoryTerm forKey:kDefaultCategoryTermKey];
  }
}

- (long long)diskCushion {
  NSUserDefaults *ud = [self userDefaults];
  NSNumber *diskCushionN = [ud objectForKey:kDiskFreeSpaceKey];
  if ([diskCushionN respondsToSelector:@selector(longLongValue)]) {
    return [diskCushionN longLongValue];
  }
  return 0;
}

- (void)setDiskCushion:(long long)diskCushion {
  NSUserDefaults *ud = [self userDefaults];
  [ud setObject:[NSNumber numberWithLongLong:diskCushion] forKey:kDiskFreeSpaceKey];
}

- (NSString *)lastDocumentPath {
  NSUserDefaults *ud = [self userDefaults];
  return [ud stringForKey:kLastDocumentPath];
}

// experiments show we can get called very late in the app's life time
// so we sync the preferences file here.
- (void)setLastDocumentPath:(NSString *)lastDocumentPath {
  NSUserDefaults *ud = [self userDefaults];
  if (lastDocumentPath) {
    [ud setObject:lastDocumentPath forKey:kLastDocumentPath];
  } else {
    [ud removeObjectForKey:kLastDocumentPath];
  }
  [self synchronize];
}

- (BOOL)isGDataHTTPLogging {
  NSUserDefaults *ud = [self userDefaults];
  return [ud boolForKey:@"isGDataHTTPLogging"];
}

- (BOOL)isAnyUserNameAllowed {
  NSUserDefaults *ud = [self userDefaults];
  return [ud boolForKey:@"isAnyUserNameAllowed"];
}


- (NSString *)appID {
  NSUserDefaults *ud = [self userDefaults];
  NSString *val = [ud stringForKey:kAppID];
  if (0 == [val length]) {
    val = NewUUID();
    [ud setObject:val forKey:kAppID];
  }
  return val;
}

- (NSString *)nextDocumentID {
  NSUserDefaults *ud = [self userDefaults];
  NSNumber *n = [ud objectForKey:kLastDocumentID];
  long long documentID = 0;
  if ([n respondsToSelector:@selector(longLongValue)]) {
    documentID = [n longLongValue];
  }
  ++documentID;
  [ud setObject:[NSNumber numberWithLongLong:documentID] forKey:kLastDocumentID];
  return [NSString stringWithFormat:@"%@-%@%lld", [self sourceIdentifier], [self appID], documentID];
}

- (NSString *)sourceIdentifier {
  return @"Vidnik";
}

// zero means don't enforce any limit
- (long long)maxMovieSize {
  long long maxMovieSize = 1000000000; // i.e. 1 billion bytes
  NSUserDefaults *ud = [self userDefaults];
  NSNumber *num = [ud objectForKey:kMaxMovieSize];
  if (num && ! [self validateMaxMovieSize:&num error:nil]) {
    maxMovieSize = [num longLongValue];
  }
  return maxMovieSize;
}

- (void)setMaxMovieSize:(long long)maxMovieSize {
  NSUserDefaults *ud = [self userDefaults];
  [ud setObject:[NSNumber numberWithLongLong:maxMovieSize] forKey:kMaxMovieSize];
}

- (BOOL)validateMaxMovieSize:(id *)ioValue error:(NSError **)outError {
  NSNumber *num = *ioValue;
  if (nil == num) {
    return YES;
  }
  if ( ! [num respondsToSelector:@selector(longLongValue)]) {
    if (outError) {
      *outError = [NSError errorWithDomain:kTDAppDomain
                                      code:kNumberExpectedErr 
                                  userInfo:nil];
    }
    return NO;
  }
  long long n = [num longLongValue];
  if (0 != n && n < 10000) {
    if (outError) {
      *outError = [NSError errorWithDomain:kTDAppDomain
                                      code:kMaxMovieSizeTooSmallErr 
                                  userInfo:nil];
    }
    return NO;
  }
  return YES;
}


// zero means don't enforce any limit
- (long)maxMovieDuration {
  long maxMovieDuration = 60; // i.e. 10 minutes
  NSUserDefaults *ud = [self userDefaults];
  NSNumber *num = [ud objectForKey:kMaxMovieDuration];
  if (num && ! [self validateMaxMovieDuration:&num error:nil]) {
    maxMovieDuration = [num longValue];
  }
  return maxMovieDuration;
}

- (void)setMaxMovieDuration:(long)maxMovieDuration {
  NSUserDefaults *ud = [self userDefaults];
  [ud setObject:[NSNumber numberWithLong:maxMovieDuration] forKey:kMaxMovieDuration];
}

- (BOOL)validateMaxMovieDuration:(id *)ioValue error:(NSError **)outError {
  NSNumber *num = *ioValue;
  if (nil == num) {
    return YES;
  }
  if ( ! [num respondsToSelector:@selector(longValue)]) {
    if (outError) {
      *outError = [NSError errorWithDomain:kTDAppDomain
                                      code:kNumberExpectedErr 
                                  userInfo:nil];
    }
    return NO;
  }
  long long n = [num longValue];
  if (0 != n && n < 10) {
    if (outError) {
      *outError = [NSError errorWithDomain:kTDAppDomain
                                      code:kMaxMovieDurationTooSmallErr 
                                  userInfo:nil];
    }
    return NO;
  }
  return YES;
}


- (NSString *)movieFolderPath {
  NSUserDefaults *ud = [self userDefaults];
  NSString *movieFolderPath = [[ud stringForKey:kMovieFolderKey] stringByExpandingTildeInPath];
  if (movieFolderPath && ! [self validateMovieFolderPath:&movieFolderPath error:nil]) {
    movieFolderPath = [NSString stringWithPathForFolder:kMovieDocumentsFolderType 
                                           subfolderName:@"Vidnik" 
                                                inDomain:kUserDomain
                                                doCreate:YES];
  }
  return movieFolderPath;
}

- (void)setMovieFolderPath:(NSString *)movieFolderPath {
  NSString *abbrevPath = [movieFolderPath stringByAbbreviatingWithTildeInPath];
  if (abbrevPath) {
    NSUserDefaults *ud = [self userDefaults];
    [ud setObject:abbrevPath forKey:kMovieFolderKey];
  }
}


- (BOOL)validateMovieFolderPath:(id *)ioValue error:(NSError **)outError {
  NSString *path = *ioValue;
  if(nil == path ||
      ([path respondsToSelector:@selector(isWritableFolderPath)] && 
      [path isWritableFolderPath])) {
    return YES;
  }
  if (outError) {
    NSDictionary *info = nil;
    if ([path respondsToSelector:@selector(characterAtIndex:)]) {
      info = [NSDictionary dictionaryWithObjectsAndKeys:
          path, NSFilePathErrorKey,
          nil];
    }
    *outError = [NSError errorWithDomain:kTDAppDomain
                                    code:kCouldNotWriteToMovieFolder 
                                userInfo:info];
  }
  return NO;
}


- (NSString *)userAgent {
  return [NSString stringWithFormat:@"google.code-%@-1.0", [self sourceIdentifier]];
}

- (NSString *)youTubeClientID {
#ifndef kYouTubeClientID
#warning "Get your own Client ID from YouTube and edit it into DeveloperKey.h See http://code.google.com/apis/youtube/overview.html"
#define kYouTubeClientID @"fakeClientID"
#endif
  return kYouTubeClientID;
}

- (NSString *)youTubeDeveloperKey {
#ifndef kYouTubeDeveloperKey
#warning "Get your own Developer Key from YouTube and edit it into DeveloperKey.h"
#define kYouTubeDeveloperKey @"fakeDeveloperKey"
#endif
  return kYouTubeDeveloperKey;
}

@end
@implementation TDConfiguration(PrivateMethods)
- (NSUserDefaults *)userDefaults {
  if (gUD) {
    return gUD;
  }
  return [NSUserDefaults standardUserDefaults];
}
@end


NSString * const kCategoriesWillChange = @"kCategoriesWillChange";
NSString * const kCategoriesDidChange = @"kCategoriesDidChange";

TDConfiguration *TDConfig(void) {
  return [[NSApp delegate] config];
}


//  mVideoPreviewQuality = codecNormalQuality;
//  mVideoPreviewFrameRate = 0.; // native

