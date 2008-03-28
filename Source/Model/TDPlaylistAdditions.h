//
//  TDPlaylistAdditions.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/1/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDModelPlaylist.h"

@class QTMovie;

// additional methods not directly related to the job of bing a model.
@interface TDModelPlaylist(Additions)

- (void)removeModelMovies:(NSArray *)modelMovies;

- (void)updateReadyToUploadState;

- (NSString *)nextUntitledMovieTitle;

- (BOOL)containsModelMovie:(TDModelMovie *)modelMovie;

- (BOOL)updateMovieFilesIfNeeded;

// ### Filters

- (TDModelMovie *)firstMovieWithTitle:(NSString *)title;

- (TDModelMovie *)firstMovieReadyToUpload;

- (TDModelMovie *)findModelMovieWithMovie:(QTMovie *)movie;

- (NSArray *)moviesReadyToUpload;

- (NSArray *)moviesThatHaveBeenUploaded;

// ### TDModelUploadingAction callback. argument is progress cell.

- (void)userCancelledUploading:(TDModelMovie *)mm;

// ### Applescript support

// This class is invisible in appleScripts, so it delegates this chore to its delegate.
- (NSScriptObjectSpecifier *)objectSpecifier;

- (void)setSelectedModelMovie:(TDModelMovie *)mm;

@end
