//
//  TDModelMovie.m
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

#import "TDModelMovie.h"
#import "TDModelMovieAdditions.h"
#import "Array+Unique.h"
#import "GDataObject.h" // for AreEqualOrBothNil()
#import "Image+Resize.h"
#import "QTMovie+Async.h"
#import "String+Path.h"
#import "TDModelFileRef.h"
#import "TDModelDate.h"
#import "TDModelUploadingAction.h"
#import "TDQTKit.h"

static NSString * const kCategoryKey = @"category";
static NSString * const kDetailsKey = @"details";
static NSString * const kDisplayDateKey = @"displayDate";
static NSString * const kKeywordsKey = @"keywords";
static NSString * const kMovieFileKey = @"movieFile";
static NSString * const kTitleKey = @"title";
static NSString * const kThumbnailKey = @"thumbnail";
static NSString * const kURLKey = @"url";
static NSString * const kMovieStateKey = @"movieState";

@interface TDModelMovie(PrivateMethods)
- (void)tellDelegateDidChangeKey:(NSString *)key oldValue:(id)value;

- (void)setThumbnailSimple:(NSImage *)thumbnail;


@end


@implementation TDModelMovie

- (id)initWithURL:(NSURL *)url ownerURL:(NSURL *)ownerURL error:(NSError **)error {
  self = [super init];
  if (self) {
    QTMovie *mov = [QTMovie asyncMovieWithURL:url error:error];
    if (nil == mov) {
      [self release];
      return nil;
    }
// TODO: must have a video channel with at least 2 samples in it.
    [self setMovieFileRef:[TDModelFileRef modelFileRefWithPath:[url path] ownerPath:[ownerURL path]]];
    [self setMovie:mov];
    mMovieState = kReadyToUpload;
  }
  return self;
}

- (void)dealloc {
  [mCategory release];
  [mDetails release];
  [mDisplayDate release];
  [mKeywords release];
  [mMovie unregisterNeedsUpdate];
  [mMovie release];
  [mMovieFile release];
  [mThumbnail release];
  [mUploadingAction release];
  [mTitle release];
  [mURL release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  TDModelMovie *m = [[TDModelMovie allocWithZone:zone] init];
  if (m) {
    m->mThumbnail = [mThumbnail copyWithZone:zone]; // must be before movieFile
    m->mTitle = [mTitle copyWithZone:zone];

    m->mCategory = [mCategory copyWithZone:zone];
    m->mDetails = [mDetails copyWithZone:zone]; 
    m->mDisplayDate = [mDisplayDate copyWithZone:zone];
    m->mKeywords = [mKeywords mutableCopyWithZone:zone]; 
    m->mMovieFile = [mMovieFile copyWithZone:zone]; // must be before movie
    m->mMovie = [mMovie copyWithZone:zone];      
    m->mURL = [mURL copyWithZone:zone];
    m->mUploadingAction = [mUploadingAction copyWithZone:zone];
    [m->mUploadingAction setDelegate:m];
    m->mMovieState = mMovieState;
  }
  return m;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (mCategory) { [coder encodeObject:mCategory forKey:kCategoryKey]; }
  if (mDetails) { [coder encodeObject:mDetails forKey:kDetailsKey]; }
  if (mDisplayDate) { [coder encodeObject:mDisplayDate forKey:kDisplayDateKey]; }
  if (mKeywords) { [coder encodeObject:mKeywords forKey:kKeywordsKey]; }
  // mMovie is intentially not stored.
  [mMovie updateMovieFileIfNeeded];
  if (mMovieFile) { [coder encodeObject:mMovieFile forKey:kMovieFileKey]; }
  if (mThumbnail) { [coder encodeObject:[mThumbnail conciseRepresentation] forKey:kThumbnailKey]; }
  if (mTitle) { [coder encodeObject:mTitle forKey:kTitleKey]; }
  if (mURL) { [coder encodeObject:mURL forKey:kURLKey]; }
  int i = mMovieState;
  [coder encodeInt:i forKey:kMovieStateKey];
}

- (id)initWithCoder:(NSCoder *)coder {
  mTitle = [[coder decodeObjectForKey:kTitleKey] retain]; // must be before movie
  mThumbnail = [[coder decodeObjectForKey:kThumbnailKey] retain]; // must be before movie

  mCategory = [[coder decodeObjectForKey:kCategoryKey] retain];
  mDetails = [[coder decodeObjectForKey:kDetailsKey] retain];
  mDisplayDate = [[coder decodeObjectForKey:kDisplayDateKey] retain];
  mKeywords = [[coder decodeObjectForKey:kKeywordsKey] retain];
  mMovieFile = [[coder decodeObjectForKey:kMovieFileKey] retain];
  mURL = [[coder decodeObjectForKey:kURLKey] retain];
  mMovieState = [coder decodeIntForKey:kMovieStateKey];

  // when reading a file, forgive past errors.
  switch (mMovieState) {
  case kUploading:
  case kUploadingCancelled:
  case kUploadingErrored:
    mMovieState = kNotReadyToUpload;
    break;
  default:
    break;
  }
  [self updateReadyToUploadState];
  return self;
}

// ### attributes
- (NSString *)category {
  return mCategory;
}

- (void)setCategory:(NSString *)category {
 if ( ! AreEqualOrBothNil(category, mCategory)) {
    NSString *oldCategory = mCategory;
    [mCategory autorelease];
    mCategory = [category copy];
    [self tellDelegateDidChangeKey:@"setCategory:" oldValue:oldCategory];
  }
}

- (id)delegate {
  return mDelegate;
}
- (void)setDelegate:(id)delegate {
  mDelegate = delegate;
}

- (NSString *)details {
  return mDetails;
}

- (void)setDetails:(NSString *)details {
 if ( ! AreEqualOrBothNil(details, mDetails)) {
    NSString *oldDetails = mDetails;
    [mDetails autorelease];
    mDetails = [details copy];
    [self tellDelegateDidChangeKey:@"setDetails:" oldValue:oldDetails];
  }
}


- (TDModelDate *)displayDate {
  return mDisplayDate;
}

- (void)setDisplayDate:(TDModelDate *)displayDate {
  if ( ! AreEqualOrBothNil(displayDate, mDisplayDate)) {
    TDModelDate *oldDisplayDate = mDisplayDate;
    [mDisplayDate autorelease];
    mDisplayDate = [displayDate retain];
    [self tellDelegateDidChangeKey:@"setDisplayDate:" oldValue:oldDisplayDate];
  }
}



- (NSArray *)keywords {
  return mKeywords;
}

- (void)setKeywords:(NSArray *)keywords {
  keywords = [keywords unique];
  if ( ! AreEqualOrBothNil(keywords, mKeywords)) {
    NSArray *oldKeywords = mKeywords;
    [mKeywords autorelease];
    mKeywords = [keywords retain];
    [self tellDelegateDidChangeKey:@"setKeywords:" oldValue:oldKeywords];
  }
}


- (QTMovie *)movie {
  NSString *path;
  NSURL *url;
  QTMovie *mov;
  NSError *error = nil;
  if (nil == mMovie && nil != (path = [mMovieFile path]) &&
    nil != (url = [NSURL fileURLWithPath:path]) && 
    nil != (mov = [QTMovie asyncMovieWithURL:url error:&error])) {

    // we don't store the movie in the document, so we may need to get it again.
    [self setMovie:mov];
  }
  return mMovie;
}

- (void)setMovie:(QTMovie *)movie {
  if (mMovie != movie) {
    [mMovie autorelease];
    mMovie = [movie retain];

    [self setDefaultThumbnailFromMovie];
    if (movie) {
      if (0 == [mTitle length]) {
        NSString *title = [movie attributeForKey:QTMovieDisplayNameAttribute];
        if (nil == title) {
          title = [movie attributeForKey:QTMovieFileNameAttribute];
        }
        [self setTitle:title];
      }
      if (kNotReadyToUpload == mMovieState && mCategory && mMovieFile) {
        mMovieState = kReadyToUpload;
      }
    }
    [self tellDelegateDidChangeKey:@"setMovie:" oldValue:nil];
  }
}

- (TDModelFileRef *)movieFileRef {
  return mMovieFile;
}

- (void)setMovieFileRef:(TDModelFileRef *)movieFileRef {
  [mMovieFile autorelease];
  mMovieFile = [movieFileRef retain];
}

- (NSString *)title {
  return mTitle;
}

- (void)setTitle:(NSString *)title {
  if ( ! AreEqualOrBothNil(title, mTitle)) {
    NSString *oldTitle = mTitle;
    [mTitle autorelease];
    mTitle = [title copy];
    [self tellDelegateDidChangeKey:@"setTitle:" oldValue:oldTitle];
  }
}


- (NSImage *)thumbnail {
  return mThumbnail;
}

- (void)setThumbnail:(NSImage *)thumbnail {
  if ( ! AreEqualOrBothNil(thumbnail, mThumbnail)) {
    NSImage *oldThumbnail = thumbnail;
    [self setThumbnailSimple:thumbnail];
    [self tellDelegateDidChangeKey:@"setThumbnail:" oldValue:oldThumbnail];
  }
}


- (NSString *)urlString {
  return mURL;
}

- (void)setURLString:(NSString *)url {
  if ( ! AreEqualOrBothNil(url, mURL)) {
    NSString *oldURLString = mURL;
    [mURL autorelease];
    mURL = [url copy];
    [self tellDelegateDidChangeKey:@"setURLString:" oldValue:oldURLString];
  }
}

- (ModelMovieState)movieState {
  return mMovieState;
}

- (void)setMovieState:(ModelMovieState)movieState {
  mMovieState = movieState;
  switch(mMovieState) {
  case kUploading:
    if (nil == [self uploadingAction]) {
      [self setUploadingAction:[[[TDModelUploadingAction alloc] init] autorelease]];
    }
    break;
  case kUploaded:
  case kUploadingCancelled:
  case kUploadingErrored:
    [self setUploadingAction:nil];
    break;
  default:
    break;
  }
}

- (TDModelUploadingAction *)uploadingAction {
  return mUploadingAction;
}

- (void)setUploadingAction:(TDModelUploadingAction *)uploadingAction {
  [mUploadingAction autorelease];
  mUploadingAction = [uploadingAction retain];
  [mUploadingAction setDelegate:self];
}


- (void)setDefaultThumbnailFromMovie {
  QTMovie *movie = [self movie];
  if (movie) {
    QTTime timDuration = [movie duration];
    QTTime halfTim = timDuration;
    halfTim.timeValue /= 2;
    NSImage *imag = [movie frameImageAtTime:halfTim];
    imag = [imag resizedThumbnail];
    [self setThumbnailSimple:imag];
  } else {
    [self setThumbnailSimple:nil];
  }
}



- (NSString *)path {
  NSString *path = [self pathIncludingTrash];
  if ([path isInTrash]) {
    path = nil;
  }
  return path;
}

- (NSString *)pathIncludingTrash {
  NSURL *fileURL = [self fileURL];
  NSString *path = [fileURL path];
  NSString *oldPath = [[self movieFileRef] path];
// TODO: should we check for reachability here? match with mMovieFile?
  if (path && ! [path isEqual:oldPath]) {
    TDModelFileRef *fileRef = [TDModelFileRef modelFileRefWithPath:path  ownerPath:[[self delegate] ownerPath]];
    [self setMovieFileRef:fileRef];
    [self tellDelegateDidChangeKey:@"setPath:" oldValue:oldPath];

  }
  return path;
}


- (BOOL)hasFilePath:(NSString *)path {
  return [mMovieFile hasFilePath:path];
}

- (void)performStringSelector:(NSString *)methodName forValue:(id)value {
  [self performSelector:NSSelectorFromString(methodName) withObject:value];
}

@end

@implementation TDModelMovie(PrivateMethods)


// without this, we were registering lots of useless undo records when we
// changed the selection.
- (void)setThumbnailSimple:(NSImage *)thumbnail {
  [mThumbnail autorelease];
  mThumbnail = [thumbnail retain];
}

- (void)tellDelegateDidChangeKey:(NSString *)key oldValue:(id)value {
  if (nil == value) {
    value = [NSNull null];
  }
  NSMutableDictionary *oldValue = [NSMutableDictionary dictionaryWithObjectsAndKeys: 
    value, key,
    key, @"setter",
    nil];
  [self updateReadyToUploadState];
  [[self delegate] modelMovieChanged:self userInfo:oldValue];
}

@end

