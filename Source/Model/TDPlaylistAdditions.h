//
//  TDPlaylistAdditions.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/1/08.
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
