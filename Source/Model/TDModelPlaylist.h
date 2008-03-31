//
//  TDModelPlaylist.h
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
#import "MoviePerformer.h"

@class TDModelMovie;
@class QTMovieView;

@interface TDModelPlaylist : NSObject<NSCoding, NSCopying> {
 @private
  NSString        *mAccount; // YouTube account name.
  NSString        *mDocID;   // unique id used for saving username/password pairs in keychain.
  NSMutableArray  *mModelMovies; // list of TDModelMovie
  id        mDelegate;  // WEAK
}

// OK to pass nil here: you'll get nil.
+ (TDModelPlaylist *)playListWithMovie:(TDModelMovie *)modelMovie;

// ### Attributes
- (NSString *)account;
// not undoable.
- (void)setAccount:(NSString *)account;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (NSArray *)modelMovies;
- (void)setModelMovies:(NSArray *)modelMovies;

- (NSString *)docID;
- (void)verifyDocID;

- (unsigned)modelMovieCount;
- (TDModelMovie *)modelMovieAtIndex:(unsigned)index;
- (void)addModelMovie:(TDModelMovie *)modelMovie;
- (void)insertModelMovie:(TDModelMovie *)modelMovie atIndex:(unsigned)index;
- (void)removeModelMovieAtIndex:(unsigned)index;
- (void)replaceModelMovieAtIndex:(unsigned)index withModelMovie:(TDModelMovie *)modelMovie;

// -1 if not found
- (int)indexOfModelMovie:(TDModelMovie *)modelMovie;

// -1 if not found
- (int)indexOfModelMovieWithPath:(NSString *)path;

@end

@interface NSObject(TDModelPlaylistDelegate)
- (NSUndoManager *)undoManager;

- (id<MoviePerformer>)moviePerformerForMovie:(TDModelMovie *)mm;

- (void)modelMovieChanged:(TDModelMovie *) userInfo:(NSMutableDictionary *)info;

- (void)playlistWillChange:(TDModelPlaylist *)playList;

- (void)playlistDidChange:(TDModelPlaylist *)playList;

- (NSString *)ownerPath;

- (void)userCancelledUploading:(TDModelMovie *)mm;

@end
