//
//  TDConfiguration.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import "TDConfiguration.h"
#import "TDAppController.h"
#import "DeveloperKey.h"

static NSString * const kAppID = @"appID";
static NSString * const kCategoriesKey = @"categories";
static NSString * const kCategoriesFetchDateKey = @"categoriesFetchDate";
static NSString * const kDefaultCategoryTermKey = @"defaultCategoryTerm";
static NSString * const kLastDocumentPath = @"lastDocumentPath";
static NSString * const kLastDocumentID = @"lastDocumentID";

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

- (NSString *)userAgent {
  return [NSString stringWithFormat:@"google.code-%@-1.0", [self sourceIdentifier]];
}

- (NSString *)youTubeClientID {
#ifndef kYouTubeClientID
#error Get your own Client ID from YouTube and edit it into DeveloperKey.h See http://code.google.com/apis/youtube/overview.html
#endif
  return kYouTubeClientID;
}

- (NSString *)youTubeDeveloperKey {
#ifndef kYouTubeDeveloperKey
#error Get your own Developer Key from YouTube and edit it into DeveloperKey.h 
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
