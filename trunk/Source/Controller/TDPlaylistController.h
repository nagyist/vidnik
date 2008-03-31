//
//  TDPlaylistController.h
//  Vidnik
//
//  Created by david on 2/21/08.
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
- (IBAction)copyLink:(id)sender;
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
- (IBAction)openYouTubePage:(id)sender;
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
