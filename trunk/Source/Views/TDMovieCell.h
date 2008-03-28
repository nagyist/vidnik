//
//  TDMovieCell.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/25/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
- (NSSize)cellSize;

- (NSSize)thumbnailSize;
+ (NSSize)defaultThumbnailSize;
@end
