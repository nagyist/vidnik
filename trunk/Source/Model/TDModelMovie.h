//
//  TDModelMovie.h
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

#import <Cocoa/Cocoa.h>
#import "TDQTKit.h"
#import "TDConstants.h"
#import "MoviePerformer.h"

@class TDModelFileRef;
@class TDModelDate;
@class TDModelUploadingAction;


@interface TDModelMovie : NSObject<NSCoding, NSCopying> {
 @private
  NSString            *mCategory; // tag (the non-localized version of the category)
  NSString            *mDetails;
  TDModelDate         *mDisplayDate;
  NSArray             *mKeywords;     // of NSStrings no dups allowed.
  QTMovie             *mMovie;        // not persistent
  TDModelFileRef      *mMovieFile;
  NSString            *mTitle;
  NSImage             *mThumbnail;
  NSString            *mURL;                // assigned by YouTube.
  TDModelUploadingAction *mUploadingAction; // not persistent, non-nil when uploading.
  ModelMovieState     mMovieState;
  BOOL                mIsPrivate;
  id                  mDelegate;  // weak
}

// owner may be nil. Otherwise we do a relative alias.
- (id)initWithURL:(NSURL *)url ownerURL:(NSURL *)ownerURL error:(NSError **)error;

// ### attributes
- (NSString *)category;
- (void)setCategory:(NSString *)category;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (NSString *)details;
- (void)setDetails:(NSString *)details;

- (TDModelDate *)displayDate;
- (void)setDisplayDate:(TDModelDate *)displayDate;

// at upload time, mark the movie as initially private or public.
- (BOOL)isPrivate;
- (void)setIsPrivate:(BOOL)isPrivate;

- (NSArray *)keywords;
- (void)setKeywords:(NSArray *)keywords;

- (TDModelFileRef *)movieFileRef;
- (void)setMovieFileRef:(TDModelFileRef *)movieFileRef;

- (QTMovie *)movie;
- (void)setMovie:(QTMovie *)movie;

- (NSString *)title;
- (void)setTitle:(NSString *)title;

- (NSImage *)thumbnail;
- (void)setThumbnail:(NSImage *)thumbnail;

- (NSString *)urlString;
- (void)setURLString:(NSString *)url;

- (ModelMovieState)movieState;
- (void)setMovieState:(ModelMovieState)movieState;

 // not persistent, non-nil when uploading.
- (TDModelUploadingAction *)uploadingAction;
- (void)setUploadingAction:(TDModelUploadingAction *)uploadingAction;


- (BOOL)hasFilePath:(NSString *)path;

// need a name not in NSObject, so NSUndoManager can forward the message correctly.
- (void)performStringSelector:(NSString *)methodName forValue:(id)value;

// filepath to movie. nil if in trash or not found.
- (NSString *)path;

- (NSString *)pathIncludingTrash;

// when the movie changes duration, we should update our thumbnail.
- (void)setDefaultThumbnailFromMovie;


@end

@interface NSObject(TDModelMovieDelegate)
- (void)modelMovieChanged:(TDModelMovie *)mm userInfo:(NSMutableDictionary *)info;

- (id<MoviePerformer>)moviePerformerForMovie:(TDModelMovie *)mm;

- (void)userCancelledUploading:(TDModelMovie *)mm;

// applescript support needs these 4:
- (int)indexOfModelMovie:(TDModelMovie *)modelMovie;
- (NSScriptObjectSpecifier *)objectSpecifier;
- (NSScriptClassDescription *)keyClassDescription;
- (void)setSelectedModelMovie:(TDModelMovie *)mm;

- (NSString *)ownerPath;
@end
