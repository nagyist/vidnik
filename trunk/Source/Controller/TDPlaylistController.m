//
//  TDPlaylistController.m
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

#import "TDPlaylistController.h"
#import "GDataEntryYouTubeUpload.h"
#import "GDataProgressMonitorInputStream.h"
#import "GDataServiceGoogle.h"
#import "TDClientAuthWindowController.h"
#import "TDConstants.h"
#import "TDConfiguration.h"
#import "TDModelMovieAdditions.h"
#import "TDModelPlaylist.h"
#import "TDPlaylistAdditions.h"
#import "TDModelMovie.h"
#import "TDMovieCell.h"
#import "TDModelFileRef.h"
#import "TDModelUploadingAction.h"
#import "QTMovie+Async.h"
#import "String+Path.h"
#import "Transcoding.h"
#import "UndoManager+Additions.h"

typedef struct InternalMoviePboard{
  TDModelMovie *mm;
  id  delegate;
  int delegateInstanceNum;
} InternalMoviePboard;

// an NSArchive of an NSArray of TDModelMovie
static NSString * const kTDMoviePboardType = @"com.google.code.TDMoviePboardType";

// contains pointers. 
static NSString * const kTDInternalMoviePboardType = @"com.google.code.TDInternalMoviePboardType";

@interface TDPlaylistController(PrivateMethods)
- (TDModelMovie *)modelMovieFromMenuItem:(id)sender;
- (NSArray *)moviesFromInternalPasteboard:(NSPasteboard *)pboard;
- (NSArray *)moviesFromMoviePasteboard:(NSPasteboard *)pboard error:(NSError **)errp;
- (NSArray *)pasteboardTypes; // of strings.
- (int)pasteFrom:(NSPasteboard *)pboard onto:(TDModelMovie *)mm;
- (int)pasteMovies:(NSArray *)movies onto:(TDModelMovie *)mm;
- (BOOL)copyTo:(NSPasteboard *)pboard movies:(NSArray *)movies;
- (void)setServiceToken:(NSString *)serviceToken;
- (void)fetchCredentialsAndDoTheUpload:(id)sender;
- (void)doTheUpload;
- (BOOL)doesMoveMovieActuallyMove:(TDModelMovie *)movie forInsertion:(TDModelMovie *)mm;
- (BOOL)doesMoveMoviesActuallyMove:(NSArray *)toMove forInsertion:(TDModelMovie *)mm;
- (int)indexForInsertion:(TDModelMovie *)mm;
- (void)selectionDidChange;
@end

@implementation TDPlaylistController
- (id)init {
  self = [super init];
  if (self) {
    mPlaylist = [[TDModelPlaylist alloc] init];
    [mPlaylist setDelegate:self];
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(selectionDidChange:) name:NSOutlineViewSelectionDidChangeNotification object:mOutline];
  }
  return self;
}

- (void)dealloc {
  [self setDelegate:nil];
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  [mPlaylist setDelegate:nil];
  [mPlaylist release];
  [mServiceToken release];
  [mServiceTicket cancelTicket];
  [mServiceTicket release];
  [super dealloc];
}

- (void)awakeFromNib {
  TDMovieCell *cell = [[[TDMovieCell alloc] init] autorelease];
  [cell setMenu:mGearMenu];
  [cell setEditable:YES]; // so in-place editing will work.
  [[[mOutline tableColumns] objectAtIndex:0] setDataCell:cell];
  [mOutline registerForDraggedTypes:[self pasteboardTypes]];
  [mOutline setDraggingSourceOperationMask:NSDragOperationEvery forLocal:YES];
  [mOutline setDraggingSourceOperationMask:NSDragOperationEvery forLocal:NO];
  [mOutline setAutoresizesOutlineColumn:NO];
  [mOutline setRowHeight:[cell cellSize].height];
}

// ### Attributes
#pragma mark -
#pragma mark ### Attributes

- (NSUndoManager *)undoManager {
  return [[self delegate] undoManager];
}

- (void)setAccount:(NSString *)account {
  if ( ! AreEqualOrBothNil(account, [self account])) {
    [mPlaylist setAccount:account];
    [[self delegate] setAccount:account];
  }
}

- (id)delegate {
  return mDelegate;
}

- (void)setDelegate:(id)delegate {
  mDelegate = delegate;
}


- (TDModelPlaylist *)playlist {
  return mPlaylist;
}

- (void)setPlaylist:(TDModelPlaylist *)playlist {
  if (mPlaylist != playlist) {
    [mPlaylist setDelegate:nil];
    [mPlaylist release];
    mPlaylist = [playlist retain];
    [mPlaylist setDelegate:self];
    [mOutline reloadData];
    if (0 < [mPlaylist modelMovieCount]) {
      TDModelMovie *mov = [mPlaylist modelMovieAtIndex:[mPlaylist modelMovieCount] - 1];
      [self setSelectedModelMovie:mov];
    }
  }
}

- (GDataServiceTicket *)serviceTicket {
  return mServiceTicket;
}

- (void)setServiceTicket:(GDataServiceTicket *)serviceTicket {
  [mServiceTicket autorelease];
  mServiceTicket = [serviceTicket retain];
}


- (TDModelMovie *)selectedModelMovie {
  TDModelMovie *val = mCurrent;
  if (val && [[self playlist] containsModelMovie:val]) {
    return val;
  }
  return nil;
}

- (void)setSelectedModelMovie:(TDModelMovie *)modelMovie {
  if (mCurrent != modelMovie) {
    if (nil == modelMovie) {
      mCurrent = modelMovie;
      [mOutline deselectAll:self];
      [[self delegate] selectionDidChangeInPlaylist:self];
    } else {
      int row = [mOutline rowForItem:modelMovie];
      if (0 <= row) {
        mCurrent = modelMovie;
        [mOutline selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
        [mOutline scrollRowToVisible:row];
        [[self delegate] selectionDidChangeInPlaylist:self];
      } else {
        fprintf(stderr, "warning: Attempted to select a movie (0x%lX) that isn't part of our playlist (0x%lX).\n", 
          (long unsigned int)modelMovie, (long unsigned int)mPlaylist);
      }
    }
  }
}

// ### Operations

- (BOOL)appendMovieFromURL:(NSURL *)movieURL error:(NSError **)error {
  BOOL isOK = NO;
  TDModelMovie *movie = [[[TDModelMovie alloc] 
        initWithURL:movieURL 
           ownerURL:[[self delegate] fileURL] 
              error:error] autorelease];
  if (movie) {
    [movie setCategory:[TDConfig() defaultCategoryTerm]];
    NSArray *addList = [NSArray arrayWithObject:movie];
    isOK = 0 < [self pasteMovies:addList onto:nil];
  }
  return isOK;
}


// TODO: maybe refactored as a statemachine.
- (void)startValidatingFilePaths {
  NSString *owner = [[[self delegate] fileURL] path];
  for (int i = 0; i < [mPlaylist modelMovieCount]; ++i) {
    TDModelMovie *mm = [mPlaylist modelMovieAtIndex:i];
    if ([mm validateFilePathWithOwner:owner]) {
      [[self delegate] updateChangeCount:NSChangeDone];
    }
  }
}

- (BOOL)hasMoviesErrorCheck {
  if (0 == [mPlaylist modelMovieCount]) {
    NSError *err = [NSError errorWithDomain:kTDAppDomain code:kNoMoviesErr userInfo:nil];
    [[self delegate] presentError:err];
    return NO;
  }
  return YES;
}

- (BOOL)hasSomeMoviesTheNeedUploadingErrorCheck {
  NSArray *haveBeenUploaded = [mPlaylist moviesThatHaveBeenUploaded];
  if ([mPlaylist modelMovieCount] == [haveBeenUploaded count]) {
    NSError *err = [NSError errorWithDomain:kTDAppDomain code:kAllAlreadyUploadedMoviesErr userInfo:nil];
    [[self delegate] presentError:err];
    return NO;
  }
  return YES;
}

- (BOOL)hasSomeMoviesReadyToUploadErrorCheck {
  TDModelMovie *mm = [mPlaylist firstMovieReadyToUpload];
  if (nil == mm) {
    NSError *err = [NSError errorWithDomain:kTDAppDomain code:kNoReadyToUploadMoviesErr userInfo:nil];
    [[self delegate] presentError:err];
    return NO;
  }
  return YES;
}

- (BOOL)hasCredential {
  GMAuthCredential *cred = [[self delegate] currentCredential];
  if (nil == cred) {
    [self fetchCredentialsAndDoTheUpload:self];
    return NO;
  }
  return YES;
}

// ### Actions
#pragma mark -
#pragma mark ### Actions

- (IBAction)copyLink:(id)sender {
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  NSString *urlString = [selectedMovie urlString];
  if (urlString) {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
      NSPasteboard *pb = [NSPasteboard generalPasteboard];
      [pb declareTypes:[NSArray arrayWithObjects:NSURLPboardType, NSStringPboardType, nil] owner:self];
      [url writeToPasteboard:pb];
      [pb setString:urlString forType:NSStringPboardType];
    }
  }
}

- (IBAction)copy:(id)sender {
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  if (selectedMovie) {
    [self copyTo:[NSPasteboard generalPasteboard] movies:[NSArray arrayWithObject:selectedMovie]];
  }
}

- (IBAction)cut:(id)sender {
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  if (nil != selectedMovie) {
    [self copy:self];
    [self delete:self];
    int iCount = 1;
    NSUndoManager *um = [self undoManager];
    if ( ! [um isUndoingOrRedoing]) {
      NSString *actionNameTag = @"Cut Movies3";
      if (2 == iCount) {
        actionNameTag = @"Cut Movies";
      } else if (1 == iCount) {
        actionNameTag = @"Cut Movie";
      }
      [um setActionName:NSLocalizedString(actionNameTag, @"Undo")];
    }
  }
}

- (IBAction)paste:(id)sender {
  NSPasteboard *pb = [NSPasteboard generalPasteboard]; 
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  int iCount = [self pasteFrom:pb onto:selectedMovie];
  if (0 < iCount) {
    NSUndoManager *um = [self undoManager];
    if ( ! [um isUndoingOrRedoing]) {
      NSString *actionNameTag = @"Paste Movies3";
      if (2 == iCount) {
        actionNameTag = @"Paste Movies";
      } else if (1 == iCount) {
        actionNameTag = @"Paste Movie";
      }
      [um setActionName:NSLocalizedString(actionNameTag, @"Undo")];
    }
  }
}

- (IBAction)delete:(id)sender {
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  if (nil != selectedMovie) {
    [mPlaylist removeModelMovies:[NSArray arrayWithObject:selectedMovie]];
    [self selectionDidChange];
  }
}

- (IBAction)selectAll:(id)sender {
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  if (selectedMovie) {
    [[self moviePerformerForMovie:selectedMovie] selectAll:selectedMovie];
  }
}

- (IBAction)selectNone:(id)sender {
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  if (selectedMovie) {
    [[self moviePerformerForMovie:selectedMovie] selectNone:selectedMovie];
  }
}

- (IBAction)trim:(id)sender {
  TDModelMovie *selectedMovie = [self selectedModelMovie];
  if (selectedMovie) {
    [[self moviePerformerForMovie:selectedMovie] trim:selectedMovie];
  }
}


- (IBAction)forgetCredentials:(id)sender {
  [[self delegate] discardPreviouslySavedCredential];
}

- (void)fetchCredentialsOnSuccess:(SEL)succeeded {
  TDClientAuthWindowController *authController;
  authController = [[TDClientAuthWindowController alloc]
          initWithTarget:self
       signedInSelector:succeeded
       cancelledSelector:@selector(signInUserCancelled:)
   errorMessageSelector:nil
       sourceIdentifier:[[self delegate] sourceIdentifier] // for log analysis
     serviceDisplayName:@"YouTube"
          learnMoreURL:[NSURL URLWithString:NSLocalizedString(@"http://www.youtube.com/signup", @"")]
         configuration:mDelegate];

  [authController setButtonLearnMoreTitle:NSLocalizedString(@"Learn More", @"")];

  [NSApp beginSheet:[authController window]
     modalForWindow:[[self delegate] windowForSheet]
      modalDelegate:self
     didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
        contextInfo:authController];
}
- (void)fetchCredentials:(id)sender {
  [self fetchCredentialsOnSuccess:@selector(signInSucceeded:)];
}

- (void)signInSucceeded:(TDClientAuthWindowController *)authWindow  {
  // successful authentication; get the service's token issued by Gaia,
  // then dismiss the sheet
  NSString *serviceToken = [authWindow authToken];
  
  if (serviceToken) {
    [self setServiceToken:serviceToken];
  }
  [NSApp endSheet:[authWindow window]];
}

- (void)signInSucceededAndDoTheUpload:(TDClientAuthWindowController *)authWindow  {
  [self signInSucceeded:authWindow];
  [self upload:self];
}

- (void)signInUserCancelled:(TDClientAuthWindowController *)authWindow {
  [NSApp endSheet:[authWindow window]];
}

- (void)sheetDidEnd:(NSWindow *)sheet 
         returnCode:(int)returnCode 
        contextInfo:(void  *)contextInfo {
  
  [sheet orderOut:self];
  TDClientAuthWindowController *authController = (TDClientAuthWindowController *)contextInfo;
  [authController release];
}

- (void)ticket:(GDataServiceTicket *)ticket finishedWithObject:(GDataEntryYouTubeUpload *)entry {
  TDModelMovie *mm = [ticket userData];
  if (mm) {
    [mm setMovieState:kUploaded];
    NSString *url = [[[entry links] alternateLink] href];
    [mm setURLString:url];
    [mOutline reloadItem:mm];
  }
  [[self delegate] updateChangeCount:NSChangeDone];
  [self setServiceTicket:nil];
  [self doTheUpload];
}

- (void)ticket:(GDataServiceTicket *)ticket finishedWithError:(NSError *)error {
  TDModelMovie *mm = [ticket userData];
  if (mm) {
    [mm setMovieState:kUploadingErrored];
    [mOutline reloadItem:mm];
  }
  [self setServiceTicket:nil];
  [[self delegate] presentError:error];
}

- (void)userCancelledUploading:(TDModelMovie *)mm {
  GDataServiceTicket *serviceTicket = [self serviceTicket];
  if (mm == [serviceTicket userData]) {
    [serviceTicket cancelTicket];
    [self setServiceTicket:nil];
    [mm setMovieState:kUploadingCancelled];
    [mOutline reloadItem:mm];
  }
}

- (void)stopUploading:(id)sender {
  GDataServiceTicket *serviceTicket = [self serviceTicket];
  TDModelMovie *mm = [serviceTicket userData];
  if (mm) {
    [serviceTicket cancelTicket];
    [self setServiceTicket:nil];
    [mm setMovieState:kUploadingCancelled];
    [mOutline reloadItem:mm];
  }
}

- (void)inputStream:(GDataProgressMonitorInputStream *)stream
  hasDeliveredByteCount:(unsigned long long)numberOfBytesSent  
       ofTotalByteCount:(unsigned long long)dataLength {

  GDataServiceTicket *ticket = [stream monitorSource];
  TDModelMovie *mm = [ticket userData];
  TDModelUploadingAction *action = [mm uploadingAction];
  [action setNumberOfBytesSent:numberOfBytesSent];
  [action setDataLength:dataLength];
  if (mm) {
    [mOutline reloadItem:mm];
  }
}

// require more than just a simple string.
- (BOOL)hasPasteBoardWithModelMovies {
  NSPasteboard *pboard = [NSPasteboard generalPasteboard];
  NSString *preferredType = [pboard availableTypeFromArray:[self pasteboardTypes]];
  return nil != preferredType && ! [preferredType isEqual:NSStringPboardType];
}

- (BOOL)hasSelection {
  return nil != [self selectedModelMovie];
}

- (BOOL)hasSelectionCanUpload {
  return [[self selectedModelMovie] canUpload];
}

- (BOOL)canRevealInFinderFromItem:(id)item {
  TDModelMovie *mm = [self modelMovieFromMenuItem:item];
  return [mm canRevealInFinder];
}

- (BOOL)canRevealInBrowserFromItem:(id)item {
  TDModelMovie *mm = [self modelMovieFromMenuItem:item];
  return [mm canRevealInBrowser];
}

- (BOOL)canCopyLink:(id)item {
  return [self canRevealInBrowserFromItem:item];
}

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  BOOL val = YES;
  SEL action = [anItem action];
  if (@selector(newMovie:) == action) {
    [anItem setTitle:NSLocalizedString(@"New Movie", @"File Menu")];
    return val;
  } else if (@selector(gearPressed:) == action) {
    val = NO;
  } else if (@selector(openYouTubePage:) == action) {
    val = (0 != [[[self playlist] account] length]);
  } else if (@selector(upload:) == action) {
    val = [self hasSelectionCanUpload];
    [mPublishButton setEnabled:val];
  } else if (@selector(stopUploading:) == action) {
    val = (nil != [self serviceTicket]);
  } else if (@selector(revealInFinder:) == action) {
    val = [self canRevealInFinderFromItem:anItem];
  } else if (@selector(revealInBrowser:) == action) {
    val = [self canRevealInBrowserFromItem:anItem];
  } else if (@selector(copyLink:) == action) {
    val = [self canCopyLink:anItem];
  } else if (@selector(cut:) == action) {
    val = [self hasSelection];
    if (val) {
      [anItem setTitle:NSLocalizedString(@"Cut Movie", @"Edit Menu")];
    }
  } else if (@selector(copy:) == action) {
    val = [self hasSelection];
    if (val) {
      [anItem setTitle:NSLocalizedString(@"Copy Movie", @"Edit Menu")];
    }
  } else if (@selector(paste:) == action) {
    val = [self hasPasteBoardWithModelMovies];
    if (val) {
      [anItem setTitle:NSLocalizedString(@"Paste Movie", @"Edit Menu")];
    }
  } else if (@selector(delete:) == action) {
    val = [self hasSelection];
    if (val) {
      [anItem setTitle:NSLocalizedString(@"Delete Movie", @"Edit Menu")];
    }
  } else if (@selector(selectAll:) == action ||
    @selector(selectNone:) == action ||
    @selector(trim:) == action) {

    TDModelMovie *mm = [self selectedModelMovie];
    val = mm && [[self moviePerformerForMovie:mm] validateMenuItem:anItem];
  }
  return val;
}

- (void)willResignFirstResponder:(NSResponder *)responder {
  NSMenu *mainMenu = [NSApp mainMenu];
  NSArray *menuArray = [mainMenu itemArray];
  int i, iCount = [menuArray count];
  for (i = 0; i < iCount; ++i) {
    // for each main menu.
    NSMenu *menu = [[menuArray objectAtIndex:i] submenu];
    int cutIndex = [menu indexOfItemWithTarget:nil andAction:@selector(cut:)];
    if (0 <= cutIndex) {
      NSMenuItem *item = [menu itemAtIndex:cutIndex];
      if (item) { [item setTitle:NSLocalizedString(@"Cut", @"")]; }

      int index = [menu indexOfItemWithTarget:nil andAction:@selector(copy:)];
      if (0 <= index && nil != (item = [menu itemAtIndex:index])) { 
        [item setTitle:NSLocalizedString(@"Copy", @"")];
      }

      index = [menu indexOfItemWithTarget:nil andAction:@selector(paste:)];
      if (0 <= index && nil != (item = [menu itemAtIndex:index])) { 
        [item setTitle:NSLocalizedString(@"Paste", @"")]; 
      }

      index = [menu indexOfItemWithTarget:nil andAction:@selector(delete:)];
      if (0 <= index && nil != (item = [menu itemAtIndex:index])) { 
        [item setTitle:NSLocalizedString(@"Delete", @"")]; 
      }

      return; // did it, done.
    }
  }
}


- (IBAction)gearPressed:(id)sender {
  if ([sender respondsToSelector:@selector(menu)] && [sender menu]) {
    NSEvent *event = [[sender window] currentEvent];
    NSRect frame = [sender frame];
    NSPoint location = frame.origin;
    NSEvent *superEvent = [NSEvent mouseEventWithType:[event type] 
                                             location:location
                                        modifierFlags:[event modifierFlags]
                                            timestamp:[event timestamp]
                                         windowNumber:[event windowNumber] 
                                              context:[event context]
                                          eventNumber:[event eventNumber] 
                                           clickCount:[event clickCount] 
                                             pressure:[event pressure]];
    [NSMenu popUpContextMenu:[sender menu] withEvent:superEvent forView:sender];
  }
}

- (IBAction)upload:(id)sender {
  [mPlaylist updateReadyToUploadState];
  if ([self hasMoviesErrorCheck] &&
    [self hasSomeMoviesTheNeedUploadingErrorCheck] &&
    [[self playlist] updateMovieFilesIfNeeded] &&
    [self hasSomeMoviesReadyToUploadErrorCheck] &&
    [self hasCredential]) {

    [self doTheUpload];
  } else {
    [mPublishButton setEnabled:YES];
  }
}

- (IBAction)newMovie:(id)sender {
  TDModelMovie *m = [[[TDModelMovie alloc] init] autorelease];
  [m setTitle:[mPlaylist nextUntitledMovieTitle]];
  [m setCategory:[TDConfig() defaultCategoryTerm]];
  [mPlaylist addModelMovie:m];
  [self setSelectedModelMovie:m];
  NSUndoManager *um = [self undoManager];
  if ( ! [um isUndoingOrRedoing]) {
    [um setActionName:NSLocalizedString(@"New Movie", @"Undo")];
  }
}

- (IBAction)openYouTubePage:(id)sender {
  NSWorkspace *ws = [NSWorkspace sharedWorkspace];
  NSString *s = @"http://www.youtube.com/my_videos";
// TODO: should log in if needed. 
  [ws openURL:[NSURL URLWithString:s]];
}


- (IBAction)revealInFinder:(id)sender {
  TDModelMovie *mm = [self modelMovieFromMenuItem:sender];
  if (mm) {
    NSString *moviePath = [mm path];
    if (moviePath) {
      NSWorkspace *ws = [NSWorkspace sharedWorkspace];
      [ws selectFile:moviePath inFileViewerRootedAtPath:nil];
    }
  }
}

- (IBAction)revealInBrowser:(id)sender {
  TDModelMovie *mm = [self modelMovieFromMenuItem:sender];
  if (mm) {
    NSString *movieURLString = [mm urlString];
    if (movieURLString) {
      NSWorkspace *ws = [NSWorkspace sharedWorkspace];
      [ws openURL:[NSURL URLWithString:movieURLString]];
    }
  }
}

- (IBAction)debugValidate:(id)sender {
  int i, iCount = [mPlaylist modelMovieCount];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [mPlaylist modelMovieAtIndex:i];
    QTMovie *movie = [mm movie];

#if 0
  OSStatus stat = noErr;
  ComponentInstance ci = nil;
  Component c = nil;
  ComponentDescription desc = {
    MovieExportType,
    kQTFileTypeMP4,
    0,
    canMovieExportFiles | hasMovieExportUserInterface,
    canMovieExportFiles | hasMovieExportUserInterface
  };
  if (noErr == stat) { c = FindNextComponent(nil, &desc); }
  if (noErr == stat) { stat = OpenAComponent(c, &ci); };
  if (noErr == stat) {
    QTAtomContainer atomContainer = nil;
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[@"~/settings" stringByExpandingTildeInPath]]];
    if (data) {
      atomContainer = NewHandle([data length]);
      memcpy(*atomContainer, [data bytes], [data length]);
      stat = MovieExportSetSettingsFromAtomContainer(ci, atomContainer);
      DisposeHandle(atomContainer);
    }
    stat = noErr;
  }
  if (noErr == stat) {
    Boolean cancelled = NO;
    Movie qtMovie = [movie quickTimeMovie];
    stat = MovieExportDoUserDialog(ci, qtMovie, nil, 0, GetMovieDuration(qtMovie), &cancelled);
    if (noErr == stat && ! cancelled) {
      QTAtomContainer atomContainer = nil;
      stat = MovieExportGetSettingsAsAtomContainer(ci, &atomContainer);
      if (noErr == stat && atomContainer) {
        NSData *data = [NSData dataWithBytes:*atomContainer length:GetHandleSize(atomContainer)];
        [data writeToURL:[NSURL fileURLWithPath:[@"~/settings" stringByExpandingTildeInPath]] atomically:YES];
        DisposeHandle(atomContainer);
      }
    }
    CloseComponent(ci);
  }
#endif

    if (movie && NeedsTranscoding(movie)) {
      NSError *err = nil;
      if ([mm rewriteToStartWithIFrameReturningError:&err]) {
        movie = [mm movie];
        if(NeedsTranscoding(movie)){
NSLog([mm title]);
        }
      }
    }
  }
}

#pragma mark -
#pragma mark ### NSOutlineViewDataSource
// ### NSOutlineViewDataSource
- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item {
  if (nil == item) {
    if (0 <= index && index < [mPlaylist modelMovieCount]) {
      return [mPlaylist modelMovieAtIndex:index];
    }
  }
  return nil;
}

- (void)didFinishVideoRecording:(NSURL *)movieURL ownerURL:(NSURL *)ownerURL {
  TDModelMovie *selected = [self selectedModelMovie];
  if (nil == selected || nil != [selected movieFileRef]) {
    [self newMovie:self];
    selected = [self selectedModelMovie];
  } 
  if (nil == [selected movieFileRef]) {
    [selected setMovieFileRef:[TDModelFileRef modelFileRefWithPath:[movieURL path] ownerPath:[ownerURL path]]];
    NSError *error = nil;
    QTMovie *mov = [QTMovie asyncMovieWithURL:movieURL error:&error];
    if (mov) {
      [selected setMovie:mov];
      [[self delegate] setAttributesOfNewlyRecordedModelMovie:selected];
      [[self delegate] updateChangeCount:NSChangeDone];
    } else if (error) {
      [[self delegate] presentError:error];
    }
    [mOutline reloadItem:selected];
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  if (nil == item) {
    return YES;
  }
  return NO;
}

- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  if (nil == item) {
    return [mPlaylist modelMovieCount];
  }
  return 0;
}

- (id)outlineView:(NSOutlineView *)outlineView 
     objectValueForTableColumn:(NSTableColumn *)tableColumn 
                        byItem:(id)item {
  return item;
}

- (void)outlineView:(NSOutlineView *)outlineView
     setObjectValue:(id)object 
     forTableColumn:(NSTableColumn *)tableColumn 
             byItem:(id)item {
  [item setTitle:object];
}

- (id)outlineView:(NSOutlineView *)outlineView itemForPersistentObject:(id)object {
  return object;
}

- (id)outlineView:(NSOutlineView *)outlineView persistentObjectForItem:(id)item {
  return item;
}

- (BOOL)outlineView:(NSOutlineView *)olv writeItems:(NSArray*)items toPasteboard:(NSPasteboard*)pboard {
  return [self copyTo:pboard movies:items];
}

// we allow dragging of medai files only into the playList. 
- (NSDragOperation)outlineView:(NSOutlineView*)olv validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(int)index {
  NSPasteboard *pboard = [info draggingPasteboard];
  NSString *preferredType = [pboard availableTypeFromArray:[self pasteboardTypes]];
  if (nil != item) {
    int newIndex = [olv rowForItem:item] + 1;
    if (1 == newIndex) {
      if (0 == [mPlaylist modelMovieCount]) {
        newIndex = 0;
      } else {
        NSPoint where = [info draggingLocation];
        float height = 54;
        id dataCell = [[olv outlineTableColumn] dataCell];
        if (dataCell) {
          height = [dataCell cellSize].height;
        }
        if (where.y < height/2.) {
          newIndex = 0;
        }
      }
    }
    [olv setDropItem:nil dropChildIndex:newIndex];
  }
  if ([preferredType isEqual:kTDInternalMoviePboardType]) {
    return NSDragOperationGeneric;
  } else if ([preferredType isEqual:kTDMoviePboardType]) {
    return NSDragOperationGeneric;
  } else if ([preferredType isEqual:NSFilenamesPboardType]) {
    id val = [NSPropertyListSerialization propertyListFromData:[pboard dataForType:NSFilenamesPboardType] mutabilityOption:kCFPropertyListImmutable format:nil errorDescription:nil];
    if ([val respondsToSelector:@selector(objectAtIndex:)]) {
      NSArray *m = (NSArray *)val;
      int i, iCount = [m count];
      for (i = 0; i < iCount;++i) {
        NSString *path = [m objectAtIndex:i];
// TODO: allow folders that contain media files.
        if ([QTMovie canInitWithFile:path]) {
          return NSDragOperationGeneric;
        }
      }
    }
  } else if ([QTMovie canInitWithPasteboard:pboard] ) {
    return NSDragOperationGeneric;
  }
  return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView*)olv acceptDrop:(id <NSDraggingInfo>)info item:(id)item childIndex:(int)index {
  TDModelMovie *mm = nil;
  if (0 <= index && index < [mPlaylist modelMovieCount]) {
    mm = [mPlaylist modelMovieAtIndex:index];
  }
  if (0 < index && index == [mPlaylist modelMovieCount]) {
    mm = [mPlaylist modelMovieAtIndex:index-1];
  }
  int iCount = [self pasteFrom:[info draggingPasteboard] onto:mm];
  if (0 < iCount) {
    NSUndoManager *um = [self undoManager];
    if ( ! [um isUndoingOrRedoing]) {
      NSString *actionNameTag = @"Drag Movies3";
      if (2 == iCount) {
        actionNameTag = @"Drag Movies";
      } else if (1 == iCount) {
        actionNameTag = @"Drag Movie";
      }
      [um setActionName:NSLocalizedString(actionNameTag, @"Undo")];
    }
  }
  return 0 < iCount;
}

// See also: - (NSSize)cellSize in TDMovieCell.m
//- (float)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item {
//  return 54;
//}

- (void)outlineView:(NSOutlineView *)outlineView 
    willDisplayCell:(NSCell *)aCell 
     forTableColumn:(NSTableColumn *)tableColumn 
               item:(id)item {
  TDModelMovie *mm = (TDModelMovie *) item;
  TDMovieCell *cell = (TDMovieCell *) aCell;
  [cell setModelMovie:mm];
  [cell setIndex:[outlineView rowForItem:item]];
}

// called from outlineView
- (void)removeObjects:(NSArray *)objects {
  [mPlaylist removeModelMovies:objects];
}

- (NSArray *)draggedObjects {
  NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
  NSString *preferredType = [pboard availableTypeFromArray:[self pasteboardTypes]];
  if ([preferredType isEqual:kTDInternalMoviePboardType]) {
    return [self moviesFromInternalPasteboard:pboard];
  }
  return nil;
}

#pragma mark -
#pragma mark ### Delegate callbacks

- (void)qtMovieChanged:(QTMovie *)movie userInfo:(NSMutableDictionary *)info {
  TDModelMovie *mm = [[self playlist] findModelMovieWithMovie:movie];
  if (mm) {
    [mm setDefaultThumbnailFromMovie];
    [mOutline reloadItem:mm];
  }
}



- (void)modelMovieChanged:(TDModelMovie *)mm userInfo:(NSMutableDictionary *)info {
  int index;
  if (mm && 0 <= (index = [mOutline rowForItem:mm])) {
    [info setObject:self forKey:@"controller"];
    NSString *key = [info objectForKey:@"setter"];
    if (key && ! ([@"setMovie:" isEqual:key] || [@"setPath:" isEqual:key])) { 
      // setMovie is not undoable, but does update.
      id value = [info objectForKey:key];
      if ([value isEqual:[NSNull null]]) {
        value = nil;
      }
      NSUndoManager *um = [self undoManager];
      [[um prepareWithInvocationTarget:mm] performStringSelector:key forValue:value];
      if ( ! [um isUndoingOrRedoing]) {
        [um setActionName:NSLocalizedString(key, @"Undo")];
      }
    }
    [mOutline reloadItem:mm];
    [[self delegate] modelMovieChanged:mm userInfo:info];
  }
}

- (void)playlistWillChange:(TDModelPlaylist *)playList {
}

- (void)playlistDidChange:(TDModelPlaylist *)playList {
  // handle the case where the current movie got deleted.
  TDModelMovie *selected = [self selectedModelMovie];
  if (selected && [mPlaylist indexOfModelMovie:selected] < 0) {
    [self setSelectedModelMovie:nil];
  }
  [mOutline reloadData];
}

- (NSString *)ownerPath {
  return [[self delegate] ownerPath];
}

// ### Applescript support
#pragma mark -
#pragma mark ### Applescript support
- (NSScriptObjectSpecifier *)objectSpecifier {
  return [mDelegate objectSpecifier];
}

// ### implement delegate of playlist
- (id<MoviePerformer>)moviePerformerForMovie:(TDModelMovie *)mm {
  if ([self selectedModelMovie] == mm) {
    return [mDelegate moviePerformer];
  }
  return nil;
}


#pragma mark -
#pragma mark ### Notications
// ### Notications

- (void)selectionDidChange:(NSNotification *)notify {
  [self selectionDidChange];
}

@end

@implementation TDPlaylistController(PrivateMethods)

- (void)copyInternalTo:(NSPasteboard *)pb movies:(NSArray *)movies {
  NSMutableArray *array = [NSMutableArray array];
  int iCount = [movies count];
  for (int i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [movies objectAtIndex:i];
    InternalMoviePboard internalMoviePboard;
    internalMoviePboard.mm = mm;
    internalMoviePboard.delegate = mDelegate;
    internalMoviePboard.delegateInstanceNum = [[self delegate] instanceNumber];
    NSData *internalMovieData = [NSData dataWithBytes:&internalMoviePboard length:(sizeof internalMoviePboard)];
    [array addObject:internalMovieData];
  }
  [pb setPropertyList:array forType:kTDInternalMoviePboardType];
}

- (void)copyMoviesTo:(NSPasteboard *)pb movies:(NSArray *)movies {
  [pb setData:[NSKeyedArchiver archivedDataWithRootObject:movies]
      forType:kTDMoviePboardType];
}

- (void)copyFilesTo:(NSPasteboard *)pb movies:(NSArray *)movies {
  NSMutableArray *array = [NSMutableArray array];
  int iCount = [movies count];
  for (int i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [movies objectAtIndex:i];
    NSString *path = [mm path];
    if (0 < [path length]) {
      [array addObject:path];
    }
  }
  if (0 < [array count]) {
    [pb setPropertyList:array forType:NSFilenamesPboardType];
  }
}

- (void)copyStringsTo:(NSPasteboard *)pb movies:(NSArray *)movies {
  NSMutableString *s = [NSMutableString string];
  int iCount = [movies count];
  for (int i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [movies objectAtIndex:i];
    NSString *s1 = [mm stringRepresentationForPasteBoard];
    if (0 != i) {
      [s appendString:@"---\n"];
    }
    [s appendString:s1];
  }
  if (0 < [s length]) {
    [pb setString:s forType:NSStringPboardType];
  }
}


- (BOOL)copyTo:(NSPasteboard *)pb movies:(NSArray *)movies {
  BOOL val = NO;
  int iCount = [movies count];
  if (0 < iCount) {
    NSString *path = nil;
    for (int i = 0; i < iCount; ++i) {
      TDModelMovie *mm = [movies objectAtIndex:i];
      if (nil != (path = [mm path])) {
        break;
      }
    }
    NSMutableArray *types = [NSMutableArray arrayWithObjects: 
      kTDInternalMoviePboardType, kTDMoviePboardType, nil];
    if (0 < [path length]) {
      [types addObject:NSFilenamesPboardType];
    }
    [types addObject:NSStringPboardType];
    [pb declareTypes:types owner:self];
    [self copyInternalTo:pb movies:movies];
    [self copyMoviesTo:pb movies:movies];
    [self copyFilesTo:pb movies:movies];
    [self copyStringsTo:pb movies:movies];
    val = YES;
  }
  return val;
}

// contextual menus encode the index of the item they are operating on in their
// tag.
- (TDModelMovie *)modelMovieFromMenuItem:(id)sender {
  TDModelMovie *mm = [self selectedModelMovie];
  int index;
  TDModelMovie *m0;
  if ([sender respondsToSelector:@selector(tag)] && 
    0 <= (index = [sender tag]) && 
    nil != (m0 = [mOutline itemAtRow:index])){
    mm = m0;
  }
  return mm;
}


// TODO: at this point we are throwing away the source information:
// we allow copying from one document to another. this array might be
// from this doc, or a different doc
- (NSArray *)moviesFromInternalPasteboard:(NSPasteboard *)pboard {
  NSMutableArray *val = [NSMutableArray array];
  NSString *errs = nil;
  NSArray *movies = [NSPropertyListSerialization 
       propertyListFromData:[pboard dataForType:kTDInternalMoviePboardType] 
       mutabilityOption:kCFPropertyListImmutable 
       format:nil 
       errorDescription:&errs];
  if (errs) {
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:errs, NSLocalizedDescriptionKey, nil];
    NSError *err = [NSError errorWithDomain:kTDAppDomain code:kCantConvertPaste userInfo:info];
    [[self delegate] presentError:err];
  }
  [errs autorelease];
  if ([movies respondsToSelector:@selector(objectAtIndex:)]) {
    int i, iCount = [movies count];
    for (i = 0; i < iCount;++i) {
      NSData *data = [movies objectAtIndex:i];
      if ([data respondsToSelector:@selector(bytes)] && sizeof(InternalMoviePboard) == [data length]) {
        InternalMoviePboard internalMoviePboard;
        memmove(&internalMoviePboard, [data bytes], sizeof(InternalMoviePboard));
        NSDocumentController *dc = [NSDocumentController sharedDocumentController];
        if ([[dc documents] containsObject:internalMoviePboard.delegate] &&
            internalMoviePboard.delegateInstanceNum == [internalMoviePboard.delegate instanceNumber] &&
            0 <= [[internalMoviePboard.delegate playlist] indexOfModelMovie:internalMoviePboard.mm]) {

            [val addObject:internalMoviePboard.mm];
         }
      }
    }
  }
  return val;
}

// internal check failed. These must be from a clipping, so they are copies.
// TODO: test what happens when they refer to a movie in use by another document
- (NSArray *)moviesFromMoviePasteboard:(NSPasteboard *)pboard error:(NSError **)errp{
  NSArray *result = nil;
  NSData *data = [pboard dataForType:kTDMoviePboardType];
  if (data) {
    @try {
      result = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } @catch (NSException *except) {
      if (errp) {
        *errp = [NSError errorWithDomain:kTDAppDomain code:kCantConvertPaste userInfo:[except userInfo]];
      }
    }
  }
  return result;
}


- (int)pasteInternalMoviesFrom:(NSPasteboard *)pb onto:(TDModelMovie *)mm {
  int val = 0;
  NSArray *movies = [self moviesFromInternalPasteboard:pb];
  val = [self pasteMovies:movies onto:mm];
  return val;
}

- (int)pasteMoviesFrom:(NSPasteboard *)pb onto:(TDModelMovie *)mm {
  int val = 0;
  NSError *err = nil;
  NSArray *movies = [self moviesFromMoviePasteboard:pb error:&err];
  if (err) {
    [[self delegate] presentError:err];
  }
  val = [self pasteMovies:movies onto:mm];
  return val;
}

// might be drop from Finder.
- (int)pasteFilePathsFrom:(NSPasteboard *)pb onto:(TDModelMovie *)mm {
  int val = 0;
  NSString *errs = nil;
  NSArray *movies = [NSPropertyListSerialization 
       propertyListFromData:[pb dataForType:NSFilenamesPboardType] 
       mutabilityOption:kCFPropertyListMutableContainers
       format:nil 
       errorDescription:&errs];
  if (errs) {
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:errs, NSLocalizedDescriptionKey, nil];
    NSError *err = [NSError errorWithDomain:kTDAppDomain code:kCantConvertPaste userInfo:info];
    [[self delegate] presentError:err];
  }
  [errs autorelease];
  if ([movies respondsToSelector:@selector(objectAtIndex:)]) {
    movies = [movies sortedArrayUsingSelector:@selector(comparePathAsFinder:)];
    NSMutableArray *addList = [NSMutableArray array];
    int i, iCount = [movies count];
    for (i = 0; i < iCount; ++i) {
      NSString *path = [movies objectAtIndex:i];
      if ([QTMovie canInitWithFile:path]) {
        int index = [mPlaylist indexOfModelMovieWithPath:path];
        if (index < 0) {
          NSURL *url = [NSURL fileURLWithPath:path];
          NSError *err = nil;
          TDModelMovie *movie = [[[TDModelMovie alloc] initWithURL:url ownerURL:[[self delegate] fileURL] error:&err] autorelease];
          if (movie) {
            [movie setCategory:[TDConfig() defaultCategoryTerm]];
            [addList addObject:movie];
          }
        }
      }
    }
    val = [self pasteMovies:addList onto:mm];
  }
  return val;
}

// return count pasted.
- (int)pasteMovies:(NSArray *)movies onto:(TDModelMovie *)mm {
  TDModelMovie *selectAtFinish = nil;
  NSMutableArray *toAdd = [NSMutableArray array];
  NSMutableArray *toMove = [NSMutableArray array];
  int val = 0;
  int insertIndex = [self indexForInsertion:mm];
  int i, iCount = [movies count];

  // partition input into moves and adds.
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [movies objectAtIndex:i];
    int index = [mPlaylist indexOfModelMovie:movie];
    if (0 <= index) {
      // can't add, already here.
      movie = [mPlaylist modelMovieAtIndex:index];
      if (index < insertIndex) {
        --insertIndex;
      }
      [toMove addObject:movie];
    } else {
      [toAdd addObject:movie];
    }
  }

  // for adds, remove duplicates
  for (i = [toAdd count] - 1; 0 <= i; --i) {
    TDModelMovie *movie = [toAdd objectAtIndex:i];
    NSString *path = [movie path];
    if (path) {
      int idx = [mPlaylist indexOfModelMovieWithPath:path];
      if (0 <= idx) {
       // can't add, already here.
        [toAdd removeObjectAtIndex:i];
      }
    }
  }

  // insert the adds
  for (i = [toAdd count] - 1; 0 <= i; --i) {
    TDModelMovie *movie = [toAdd objectAtIndex:i];
    [mPlaylist insertModelMovie:movie atIndex:insertIndex];
    selectAtFinish = movie;
    val++;
  }

  // if there are some that need moving, move them.
  if ([self doesMoveMoviesActuallyMove:toMove forInsertion:mm]) {
    [mPlaylist removeModelMovies:toMove];
    for (i = [toMove count] - 1; 0 <= i; --i) {
      TDModelMovie *movie = [toMove objectAtIndex:i];
      [mPlaylist insertModelMovie:movie atIndex:insertIndex];
      selectAtFinish = movie;
      val++;
    }
  }

  if (selectAtFinish) {
    [self setSelectedModelMovie:selectAtFinish];
  }
  return val;
 }
 

- (BOOL)doesMoveMovieActuallyMove:(TDModelMovie *)movie forInsertion:(TDModelMovie *)mm {
  int oldIndex = [mPlaylist indexOfModelMovie:movie];
  int newIndex = [self indexForInsertion:mm];
  return oldIndex != newIndex;
}

- (BOOL)doesMoveMoviesActuallyMove:(NSArray *)toMove forInsertion:(TDModelMovie *)mm {
  int i, iCount = [toMove count];
  for (i = iCount-1; 0 <= i; --i) {
    TDModelMovie *movie = [toMove objectAtIndex:i];
    if ([self doesMoveMovieActuallyMove:movie forInsertion:mm]) {
      return YES;
    }
  }
  return NO;
}

- (int)indexForInsertion:(TDModelMovie *)mm {
  int insertIndex = [mPlaylist indexOfModelMovie:mm];
  if (insertIndex < 0) {
    insertIndex = [mPlaylist modelMovieCount];
  }
  return insertIndex;
}


- (NSArray *)pasteboardTypes {
  static NSArray * pasteboardTypes = nil;
  if (nil == pasteboardTypes) {
    pasteboardTypes = [[NSArray alloc] initWithObjects:
      kTDInternalMoviePboardType, kTDMoviePboardType, NSFilenamesPboardType, NSStringPboardType, nil];
  }
  return pasteboardTypes;
}

// returns count of items pasted.
- (int)pasteFrom:(NSPasteboard *)pb onto:(TDModelMovie *)mm {
  int pastedCount = 0;
  NSMutableArray *types = [[[self pasteboardTypes] mutableCopy] autorelease];
  NSString *preferredType = [pb availableTypeFromArray:types];
  if ([preferredType isEqual:kTDInternalMoviePboardType]) {
    pastedCount = [self pasteInternalMoviesFrom:pb onto:mm];
    if (0 < pastedCount) {
      return pastedCount;
    }
  }
  // stale internal format. try the persistent format.
  [types removeObject:kTDInternalMoviePboardType];
  preferredType = [pb availableTypeFromArray:types];

  if ([preferredType isEqual:kTDMoviePboardType]) {
    return [self pasteMoviesFrom:pb onto:mm];
  } else if ([preferredType isEqual:NSFilenamesPboardType]) {
    return [self pasteFilePathsFrom:pb onto:mm];
  }
  return pastedCount;
}

- (void)selectionDidChange {
  NSIndexSet *indexSet = [mOutline selectedRowIndexes];
  unsigned int i;
  TDModelMovie *m = nil;
  for (i = [indexSet firstIndex];i != NSNotFound; i = [indexSet indexGreaterThanIndex:i]) {
    m = [mOutline itemAtRow:i];
  }
  [self setSelectedModelMovie:m];
}


- (void)setServiceToken:(NSString *)serviceToken {
  [mServiceToken autorelease];
  mServiceToken = [serviceToken copy];
}

- (void)fetchCredentialsAndDoTheUpload:(id)sender {
  [self fetchCredentialsOnSuccess:@selector(signInSucceededAndDoTheUpload:)];
}

- (void)doTheUpload {
  [mPublishButton setEnabled:NO];
  TDModelMovie *mm = [mPlaylist firstMovieReadyToUpload];
  if (mm) {
    [mm setMovieState:kUploading];
    [self setServiceTicket:[[self delegate] upload1:mm
                                       target:self
                   selectorFinishedWithObject:@selector(ticket:finishedWithObject:)
                    selectorFinishedWithError:@selector(ticket:finishedWithError:)]];
  } else {
    [mPublishButton setEnabled:YES];
  }
}

@end
