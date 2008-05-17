//
//  TDPlaylistAdditions.m
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

#import "TDPlaylistAdditions.h"
#import "QTMovie+Async.h"
#import "TDModelMovie.h"
#import "UndoManager+Additions.h"



@implementation TDModelPlaylist(Additions)

- (void)removeModelMovies:(NSArray *)modelMovies {
  int i, iCount = [modelMovies count];
  BOOL didSome = NO;
  if (0 < iCount) {
    for (i = 0; i < iCount; ++i) {
      TDModelMovie *mm = [modelMovies objectAtIndex:i];
      int idx = [self indexOfModelMovie:mm];
      if (0 <= idx) {
        [self removeModelMovieAtIndex:idx];
        didSome = YES;
      }
    }

    NSUndoManager *um = [mDelegate undoManager];
    if (didSome && ! [um isUndoingOrRedoing]) {
      NSString *actionNameTag = @"Delete Movies3";
      if (2 == iCount) {
        actionNameTag = @"Delete Movies";
      } else if (1 == iCount) {
        actionNameTag = @"Delete Movie";
      }
      [um setActionName:NSLocalizedString(actionNameTag, @"Undo")];
    }
  }
}

// return YES so we can use in a conditional chain.
- (BOOL)updateMovieFilesIfNeeded {
  [mModelMovies makeObjectsPerformSelector:@selector(updateMovieFileIfNeeded)];
  return YES;
}

- (void)updateReadyToUploadState {
  [mModelMovies makeObjectsPerformSelector:@selector(updateReadyToUploadState)];
}

- (NSString *)nextUntitledMovieTitle {
  NSString *untitled = NSLocalizedString(@"UntitledMovieN", @"Used in nextUntitledMovieTitle");
  int i;
  for (i = 1; i < 1000;++i) {
    NSString *s = [NSString stringWithFormat:untitled, i];
    if (nil == [self firstMovieWithTitle:s]) {
      return s;
    }
  }
  return NSLocalizedString(@"UntitledMovie", @"Should never happen in nextUntitledMovieTitle");
}

- (BOOL)containsModelMovie:(TDModelMovie *)modelMovie {
  return 0 <= [self indexOfModelMovie:modelMovie];
}

// ### Filters
- (TDModelMovie *)firstMovieWithTitle:(NSString *)title {
  int i, iCount  = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [self modelMovieAtIndex:i];
    if ([[movie title] isEqual:title]) {
      return movie;
    }
  }
  return nil;
}

- (TDModelMovie *)firstMovieReadyToUpload {
  int i, iCount  = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [self modelMovieAtIndex:i];
    ModelMovieState movieState = [movie movieState];
    QTMovie *qtmovie;
    if (movieState == kReadyToUpload && 
      nil != (qtmovie = [movie movie]) &&
      [qtmovie hasAttributes] &&
      nil != [qtmovie attributeForKey:QTMovieURLAttribute]) {

      return movie;
    }
  }
  return nil;
}

- (NSArray *)moviesReadyToUpload {
  NSMutableArray *val = [NSMutableArray array];
  int i, iCount  = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [self modelMovieAtIndex:i];
    ModelMovieState movieState = [movie movieState];
    QTMovie *qtmovie;
    if (movieState == kReadyToUpload && 
      nil != (qtmovie = [movie movie]) &&
      [qtmovie hasAttributes] &&
      nil != [qtmovie attributeForKey:QTMovieURLAttribute]) {

      [val addObject:movie];
    }
  }
  return val;
}


- (TDModelMovie *)findModelMovieWithMovie:(QTMovie *)qtmovie {
  if (nil == qtmovie) {
    return nil;
  }
  int i, iCount  = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [self modelMovieAtIndex:i];
    if ([movie movie] == qtmovie) {
      return movie;
    }
  }
  return nil;
}



- (NSArray *)moviesThatHaveBeenUploaded {
  NSMutableArray *val = [NSMutableArray array];
  int i, iCount  = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [self modelMovieAtIndex:i];
    ModelMovieState movieState = [movie movieState];
    if (movieState == kUploaded ||
      movieState == kUploading ||
      movieState == kUploadPreprocessing) {

      [val addObject:movie];
    }
  }
  return val;
}

// ### TDModelUploadingAction callback. argument is progress cell.
#pragma mark -
#pragma mark ### TDModelUploadingAction support

- (void)userCancelledUploading:(TDModelMovie *)mm {
  [[self delegate] userCancelledUploading:mm];
}

// ### Applescript support
#pragma mark -
#pragma mark ### Applescript support
- (NSScriptObjectSpecifier *)objectSpecifier {
  return [[self delegate] objectSpecifier];
}

- (void)setSelectedModelMovie:(TDModelMovie *)mm {
  [[self delegate] setSelectedModelMovie:mm];
}

@end
