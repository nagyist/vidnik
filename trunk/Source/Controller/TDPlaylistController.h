//
//  TDPlaylistController.h
//  Vidnik
//
//  Created by david on 2/21/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>
#import "MoviePerformer.h"
#import "TDConstants.h"

@class TDModelPlaylist;
@class TDModelMovie;
@class GMAuthCredential;
@class GDataServiceTicket;
@class QTMovieView;

@interface TDPlaylistController : NSResponder {
  TDModelPlaylist *mPlaylist;
  TDModelMovie  *mCurrent;   // WEAK!
  IBOutlet NSOutlineView *mOutline;
  IBOutlet NSButton *mNewButton;
  IBOutlet NSButton *mGearButton;
  IBOutlet NSButton *mPublishButton;
  IBOutlet NSMenu   *mGearMenu;
  IBOutlet id mDelegate;
  NSString            *mServiceToken;
  GDataServiceTicket  *mServiceTicket;
}
// ### Attributes

- (NSUndoManager *)undoManager;

- (void)setAccount:(NSString *)account;

- (id)delegate;
- (void)setDelegate:(id)delegate;

- (TDModelPlaylist *)playlist;
- (void)setPlaylist:(TDModelPlaylist *)playlist;

- (TDModelMovie *)selectedModelMovie;
- (void)setSelectedModelMovie:(TDModelMovie *)modelMovie;

- (GDataServiceTicket *)serviceTicket;
- (void)setServiceTicket:(GDataServiceTicket *)serviceTicket;

// ### Operations

- (void)startValidatingFilePaths;
- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

// ### Actions
- (IBAction)copy:(id)sender;
- (IBAction)cut:(id)sender;
- (IBAction)paste:(id)sender;
- (IBAction)delete:(id)sender;

- (IBAction)selectAll:(id)sender;
- (IBAction)selectNone:(id)sender;
- (IBAction)trim:(id)sender;

- (IBAction)fetchCredentials:(id)sender;
- (IBAction)forgetCredentials:(id)sender;
- (IBAction)gearPressed:(id)sender;
- (IBAction)newMovie:(id)sender;
- (IBAction)upload:(id)sender;
- (IBAction)revealInFinder:(id)sender;
- (IBAction)revealInBrowser:(id)sender;

// ### Applescript support

// This class is invisible in appleScripts, so it delegates this chore to its delegate.
- (NSScriptObjectSpecifier *)objectSpecifier;

// ### Notications

// object is the NSURL of the recorded movie.
- (void)didFinishVideoRecording:(NSURL *)movieURL ownerURL:(NSURL *)ownerURL;

// ### implement delegate of playlist
- (id<MoviePerformer>)moviePerformerForMovie:(TDModelMovie *)mm;

@end

@interface NSObject(TDPlaylistControllerDelegate)
- (void)setAttributesOfNewlyRecordedModelMovie:(TDModelMovie *)modelMovie;

- (void)selectionDidChangeInPlaylist:(TDPlaylistController *)sender;

- (GMAuthCredential *)currentCredential;

- (GDataServiceTicket *)upload1:(TDModelMovie *)mm
                         target:(id)target
     selectorFinishedWithObject:(SEL)selectorFinished
      selectorFinishedWithError:(SEL)selectorError;

- (int)instanceNumber;

- (NSString *)ownerPath;

- (id<MoviePerformer>)moviePerformer;

@end
