//
//  TDModelPlaylist.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
