//
//  TDiaryDocument.h
//  doc
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright Google Inc 2008 . Open source under Apache license Documentation/Copying in this project
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

// ### Attributes

- (TDModelPlaylist *)playlist;
- (void)setPlaylist:(TDModelPlaylist *)playlist;

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
     selectorFinishedWithObject:(SEL)selectorFinished
      selectorFinishedWithError:(SEL)selectorError;
- (int)instanceNumber;


@end
