//
//  TDiaryDocument.h
//  doc
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright Google Inc 2008 . 
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

@class AuthCredential;
@class TDModelPlaylist;
@class TDPlaylistController;
@class TDMovieAttributesController;
@class TDSplitController;
@class VRVideoController;
@class TDModelMovie;
@class GDataServiceGoogleYouTube;
@class GDataServiceTicket;
@class QTMovie;

/* experiments show that we should not delete the IBOutlet top level objects
  here.
 */
@interface TDiaryDocument : NSDocument {
  IBOutlet TDPlaylistController *mPlaylistController;
  IBOutlet VRVideoController *mVideoController;
  IBOutlet TDMovieAttributesController *mMovieAttributesController;
  TDModelPlaylist *mTemp; // read is called before awakeFromNib, apparently.
  GDataServiceGoogleYouTube *mService;
  int mInstanceNumber;  // so if a pointer gets re-used, we'll know.
  BOOL mIsPresentingError;
  BOOL mIsSuppressingErrorDialog;
}

// from top window to last window, if window contains this existing movie,
// select the movie, return the window. 
// If no existing window contains the movie, 
// try to reopenPreviousDocument and append to it. 
// If that fails, and we have an open window, append to that window.
// otherwise, create a new document, and append the movie to THAT and return it.
+ (TDiaryDocument *)documentForMovieURL:(NSURL *)movieURL error:(NSError **)error;

// ### Attributes

- (TDModelPlaylist *)playlist;
- (void)setPlaylist:(TDModelPlaylist *)playlist;

- (TDPlaylistController *)playlistController;

- (TDModelMovie *)selectedModelMovie;
- (void)setSelectedModelMovie:(TDModelMovie *)modelMovie;

// used by unit test
- (BOOL)isSuppressingErrorDialog;
- (void)setSuppressingErrorDialog:(BOOL)isSuppressing;


// ### TDClientAuthWindowControllerConfiguration

- (GDataServiceGoogleYouTube *)service;

// unit tests will call this to mock upload.
- (void)setService:(GDataServiceGoogleYouTube *)service;

- (NSString *)sourceIdentifier;

- (NSString *)docID;

- (NSString *)keychainServiceName;

- (NSString *)account;
- (AuthCredential *)previouslySavedCredential;

// used by PlaylistController if can Upload
- (AuthCredential *)currentCredential;

- (NSString *)userAgent;
- (NSString *)youTubeClientID;
- (NSString *)youTubeDeveloperKey;

// ### Applescript support
- (NSScriptObjectSpecifier *)objectSpecifier;
- (int)orderedID;
- (int)orderedIndex;

- (NSArray *)modelMovies;
- (void)setModelMovies:(NSArray *)modelMovies;
- (unsigned)modelMovieCount;
- (TDModelMovie *)modelMovieAtIndex:(unsigned)index;
- (void)addModelMovie:(TDModelMovie *)modelMovie;
- (void)insertModelMovie:(TDModelMovie *)modelMovie atIndex:(unsigned)index;
- (void)removeModelMovieAtIndex:(unsigned)index;
- (void)replaceModelMovieAtIndex:(unsigned)index withModelMovie:(TDModelMovie *)modelMovie;


// ### delegate callbacks
- (id<MoviePerformer>)moviePerformer;

- (void)modelMovieChanged:(TDModelMovie *)mm userInfo:(NSMutableDictionary *)info;

- (void)qtMovieChanged:(QTMovie *)movie userInfo:(NSMutableDictionary *)info;


- (void)didFinishVideoRecording:(NSURL *)movieURL;

- (void)setAttributesOfNewlyRecordedModelMovie:(TDModelMovie *)modelMovie;

- (GDataServiceTicket *)upload1:(TDModelMovie *)mm
                         target:(id)target
     selectorFinishedWithObject:(SEL)selectorFinished;

- (int)instanceNumber;


@end
