//
//  TDMovieCell.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/25/08.
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
#import "TDModelMovie.h"

@class ProgressCell;
@class TDModelUploadingAction;

typedef enum MovieFilePresentState {
  kMovieFilePresent,
  kMovieFileAbsent,
  kMovieFileNotYetDetermined
} MovieFilePresentState;

// TDMovieCell is a compound cell. It contains:
// an image (the movie), the movie's title,
// a ProgressCell (itself a compound cell, with a progress meter, cancel button,
//    and text related to the upload progress)
// Possibly it may have more: using the space used by the progress cell,
//    when not uploading.
@interface TDMovieCell : NSTextFieldCell {
@private
  NSImage       *mThumbnail;
  ProgressCell  *mProgressCell;
  ModelMovieState mMovieState;
  MovieFilePresentState mMovieFilePresentState;
  int mIndex;
  TDModelUploadingAction *mAction;
}

- (NSImage *)thumbnail;
- (void)setThumbnail:(NSImage *)thumbnail;

- (void)setTitle:(NSString *)title;
- (void)setCategory:(NSString *)category;
- (void)setKeywords:(NSArray *)keywords;
- (void)setDetails:(NSString *)details;
- (void)setMovieState:(ModelMovieState)movieState;
- (void)setIndex:(int)index;
- (void)setUploadingAction:(TDModelUploadingAction *)action;

// convenience wrapper: copies state out of modelMovie using the above setters.
- (void)setModelMovie:(TDModelMovie *)modelMovie;


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;

- (NSSize)thumbnailSize;
+ (NSSize)defaultThumbnailSize;
@end
