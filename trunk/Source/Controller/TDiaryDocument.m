//
//  TDiaryDocument.m
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

#import "TDiaryDocument.h"
#import "AuthCredential.h"
#import "GDataEntryYouTubeUpload.h"
#import "GDataEntryYouTubeVideo.h"
#import "GDataObject.h" // for AreEqualOrBothNil
#import "GDataMediaCategory.h"
#import "GDataServiceGoogleYouTube.h"
#import "GDataYouTubeMediaElements.h"
#import "GDataMediaKeywords.h"
#import "TDConfiguration.h"
#import "TDConstants.h"
#import "TDModelMovie.h"
#import "TDModelMovieAdditions.h"
#import "TDModelPlaylist.h"
#import "TDMovieAttributesController.h"
#import "TDPlaylistAdditions.h"
#import "TDPlaylistController.h"
#import "VRVideoController.h"

// Augment an error with localized descriptions and suggestions
static NSError *AugmentError(NSError *err, NSString *errKey, NSString *suggestKey);

@implementation TDiaryDocument

// ### Create / Destroy
- (void)dealloc {
  [mTemp release];
  [mService release];
  [super dealloc];
}

// ### Attributes

- (TDModelPlaylist *)playlist {
  return [mPlaylistController playlist];
}

- (void)setPlaylist:(TDModelPlaylist *)playlist {
  [mPlaylistController setPlaylist:playlist];
}

- (TDModelMovie *)selectedModelMovie {
  return [mPlaylistController selectedModelMovie];
}

- (void)setSelectedModelMovie:(TDModelMovie *)modelMovie {
  [mPlaylistController setSelectedModelMovie:modelMovie];
}

// callback when selection changes in the playlist Table.
- (void)selectionDidChangeInPlaylist:(TDPlaylistController *)list {
  TDModelMovie *modelMovie = [list selectedModelMovie];
  QTMovie *movie = [modelMovie movie];
  [mVideoController setMovie:movie];
  [mMovieAttributesController setModelMovie:modelMovie];
}

// ### To Window

- (NSString *)windowNibName {
    return @"TDiaryDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController {
  static int sInstanceNumber = 0; // so if a pointer gets re-used, we'll know.
  mInstanceNumber = sInstanceNumber++;
  [super windowControllerDidLoadNib:aController];
  // put out subcontrollers in the responder chain
  NSResponder *prevResponder = [aController nextResponder];
  [aController setNextResponder:mMovieAttributesController];
  [mMovieAttributesController setNextResponder:mVideoController];
  [mVideoController setNextResponder:mPlaylistController];
  [mPlaylistController setNextResponder:prevResponder];
  if ([mTemp modelMovieCount]) {
    [self setPlaylist:mTemp];
    [self setSelectedModelMovie:[mTemp modelMovieAtIndex:0]];
    [mTemp release];  // now owned by playListController
    if (nil == [mTemp docID]) {
      [mTemp verifyDocID];
    }
    mTemp = nil;
  } else {
    // new untitled document 
    NSUndoManager *um = [self undoManager];
    BOOL wasUndoRegistrationEnabled = [um isUndoRegistrationEnabled];
    [um disableUndoRegistration];

    TDModelPlaylist *pl = [[[TDModelPlaylist alloc] init] autorelease];
    TDModelMovie *m = [[[TDModelMovie alloc] init] autorelease];
    [m setTitle:[pl nextUntitledMovieTitle]];
    [pl addModelMovie:m];
    [self setPlaylist:pl];
 
    if (wasUndoRegistrationEnabled) {
      [um enableUndoRegistration];
    }
  }
  // at end of read, document is always in the clean state.
  [self updateChangeCount:NSChangeCleared];
}

- (void)windowDidBecomeKey:(NSNotification *)notify {
  NSArray *menus = [[NSApp mainMenu] itemArray];
  int i, iCount = [menus count];
  for (i = 0; i < iCount; ++i) {
    NSMenu *menu = [[menus objectAtIndex:i] submenu];
    int indx = [menu indexOfItemWithTarget:nil andAction:@selector(fetchCredentials:)];
    if (0 <= indx) {
      NSMenuItem *item = [menu itemAtIndex:indx];
      if ([self account]) {
        [item setTitle:NSLocalizedString(@"Change Account", @"")];
      } else { 
        [item setTitle:NSLocalizedString(@"Set Account", @"")];
      }
    }
  }
}

- (void)setAttributesOfNewlyRecordedModelMovie:(TDModelMovie *)modelMovie {
    NSUndoManager *um = [self undoManager];
    BOOL wasUndoRegistrationEnabled = [um isUndoRegistrationEnabled];
    [um disableUndoRegistration];

    [modelMovie setTitle:[mMovieAttributesController title]];
    [modelMovie setKeywords:[mMovieAttributesController keywords]];
    [modelMovie setDetails:[mMovieAttributesController details]];
    [modelMovie setCategory:[mMovieAttributesController category]];

    if (wasUndoRegistrationEnabled) {
      [um enableUndoRegistration];
    }
}

// called when app becomes active
- (void)startValidatingFilePaths {
  [mPlaylistController startValidatingFilePaths];
}

- (void)qtMovieChanged:(QTMovie *)movie userInfo:(NSMutableDictionary *)info {
  id controller = [info objectForKey:@"controller"];
  if (controller != mPlaylistController) {
    [mPlaylistController qtMovieChanged:movie userInfo:info];
  }
  if (controller != mVideoController) {
    [mVideoController qtMovieChanged:movie userInfo:info];
  }
  if (controller != mMovieAttributesController) {
    [mMovieAttributesController qtMovieChanged:movie userInfo:info];
  }
}

// ### Applescript support
#pragma mark -
#pragma mark ### Applescript support

- (NSScriptObjectSpecifier *)objectSpecifier {
  return [[[NSUniqueIDSpecifier alloc] 
    initWithContainerClassDescription:(NSScriptClassDescription *)
        [NSScriptClassDescription classDescriptionForClass:[NSApp class]]
    containerSpecifier:nil 
    key:@"documents" 
    uniqueID:[NSNumber numberWithInt:mInstanceNumber]] autorelease];
}

- (NSArray *)modelMovies {
  return [[self playlist] modelMovies];
}

- (void)setModelMovies:(NSArray *)modelMovies {
  [[self playlist] setModelMovies:modelMovies];
}


- (unsigned)modelMovieCount {
  return [[self playlist] modelMovieCount];
}


- (TDModelMovie *)modelMovieAtIndex:(unsigned)index {
  return [[self playlist] modelMovieAtIndex:index];
}


- (void)addModelMovie:(TDModelMovie *)modelMovie {
  [[self playlist] addModelMovie:modelMovie];
}


- (void)insertModelMovie:(TDModelMovie *)modelMovie atIndex:(unsigned)index {
  [[self playlist] insertModelMovie:modelMovie atIndex:index];
}


- (void)removeModelMovieAtIndex:(unsigned)index {
  [[self playlist] removeModelMovieAtIndex:index];
}


- (void)replaceModelMovieAtIndex:(unsigned)index withModelMovie:(TDModelMovie *)modelMovie {
  [[self playlist] replaceModelMovieAtIndex:index withModelMovie:modelMovie];
}

- (int)orderedID {
  return mInstanceNumber;
}

- (int)orderedIndex {
  return [[NSApp orderedDocuments] indexOfObject:self];
}


// ### delegate callbacks
#pragma mark -
#pragma mark ### delegate callbacks

- (id<MoviePerformer>)moviePerformer {
  return mVideoController;
}


- (void)modelMovieChanged:(TDModelMovie *)mm userInfo:(NSMutableDictionary *)info {
  id controller = [info objectForKey:@"controller"];
  if (controller != mPlaylistController) {
    [mPlaylistController modelMovieChanged:mm userInfo:info];
  }
  if (controller != mVideoController) {
    [mVideoController modelMovieChanged:mm userInfo:info];
  }
  if (controller != mMovieAttributesController) {
    [mMovieAttributesController modelMovieChanged:mm userInfo:info];
  }
}

- (BOOL)isSuppressingErrorDialog {
  return mIsSuppressingErrorDialog;
}

- (void)setSuppressingErrorDialog:(BOOL)isSuppressing {
  mIsSuppressingErrorDialog = isSuppressing;
}

- (void)didFinishVideoRecording:(NSURL *)movieURL {
  [mPlaylistController didFinishVideoRecording:movieURL ownerURL:[self fileURL]];
}


- (void)didPresentError:(BOOL)didRecover contextInfo:(void *)contextInfo {
  mIsPresentingError = NO;
}

- (NSError *)willPresentError:(NSError *)error {
  if ([[error domain] isEqual:@"com.google.GDataServiceDomain"]) {
    switch ([error code]) {
    case 401:
      [mPlaylistController setAccount:nil];
// Auth error?
      break;
    default:
      break;
    }
  } else if ([[error domain] isEqual:kTDAppDomain]) {
    switch ([error code]) {
    case kAllAlreadyUploadedMoviesErr:
      return AugmentError(error, @"UploadErrAllAlreadyUploadedMovies", @"UploadSuggestAllAlreadyUploadedMovies");
    case kCouldNotWriteToMovieFolder:
      return AugmentError(error, @"CouldNotWriteToMovieFolderErr", @"CouldNotWriteToMovieFolderSuggest");
    case kMaxMovieDurationTooSmallErr:
      return AugmentError(error, @"MaxMovieDurationTooSmallErr", @"MaxMovieDurationTooSmallSuggest");
    case kMaxMovieSizeTooSmallErr:
      return AugmentError(error, @"MaxMovieSizeTooSmallErr", @"MaxMovieSizeTooSmallSuggest");
    case kNoCameraErr:
      return AugmentError(error, @"NoCameraErr", @"NoCameraSuggest");
    case kNoMoviesErr:
      return AugmentError(error, @"UploadErrNoMovies", @"UploadSuggestNoMovies");
    case kNoReadyToUploadMoviesErr:
      return AugmentError(error, @"UploadErrNoReadyToUploadMovies", @"UploadSuggestNoReadyToUploadMovies");
    case kNoServiceErr:
      return AugmentError(error, @"NoServiceErr", @"NoServiceSuggest");
    case kNoUsernamePasswordErr:
      return AugmentError(error, @"NoUsernamePasswordErr", @"NoUsernamePasswordSuggest");
    case kNumberExpectedErr:
      return AugmentError(error, @"NumberExpectedErr", @"NumberExpectedSuggest");
    case kUploadErrCouldntReadFile:
      return AugmentError(error, @"UploadErrCouldntReadFile", @"UploadSuggestCouldntReadFile");
    case kUploadErrFileNotFound:
      return AugmentError(error, @"UploadErrFileNotFound", @"UploadSuggestFileNotFound");
    case kUploadErrNoCategory:
      return AugmentError(error, @"UploadErrNoCategory", @"UploadSuggestNoCategory");
    
    default:
      break;
    }
  }
  return [super willPresentError:error];
}


- (void)presentError:(NSError *)error {
  if ( ! mIsSuppressingErrorDialog) {
    error = [self willPresentError:error];
    NSWindow *window = [self windowForSheet];
    if (window && ! mIsPresentingError) {
      mIsPresentingError = YES;
      [self presentError:error modalForWindow:window delegate:self didPresentSelector:@selector(didPresentError:contextInfo:) contextInfo:nil];
    } else {
      [super presentError:error];
    }
  }
}

- (void)windowWillClose:(NSNotification *)notification {
  NSWindow *window = [self windowForSheet];
  NSString *filePath = nil;
  if (window == [notification object] && ! [self isDocumentEdited] &&
    nil != (filePath = [[self fileURL] path])) {

    [TDConfig() setLastDocumentPath:filePath];
  }
}

// ### File I/O

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  return [NSKeyedArchiver archivedDataWithRootObject:[self playlist]];
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError **)error {
  TDModelPlaylist *playlist = nil;
  if ([typeName isEqual:@"Movie"]) {

    NSUndoManager *um = [self undoManager];
    BOOL wasUndoRegistrationEnabled = [um isUndoRegistrationEnabled];
    [um disableUndoRegistration];

    TDModelMovie *modelMovie = [[[TDModelMovie alloc] initWithURL:url ownerURL:[self fileURL] error:error] autorelease];
    playlist = [TDModelPlaylist playListWithMovie:modelMovie];
    mTemp = [playlist retain];

    if (wasUndoRegistrationEnabled) {
      [um enableUndoRegistration];
    }
  } else {
    NSData *data = [NSData dataWithContentsOfURL:url options:NSUncachedRead error:error];
    if (data) {
      playlist = [NSKeyedUnarchiver unarchiveObjectWithData:data];
      mTemp = [playlist retain];
      if (error && nil == playlist) {
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
          NSLocalizedString(@"CouldntReadFileErr", @""), NSLocalizedDescriptionKey,
          nil];
        *error = [NSError errorWithDomain:kTDAppDomain code:kBadFileErr userInfo:info];
      }
    }
  }
  return nil != playlist;
}

- (GDataServiceTicket *)upload1:(TDModelMovie *)mm
                         target:(id)target
     selectorFinishedWithObject:(SEL)selectorFinished
                  selectorFinishedWithError:(SEL)selectorError {

  NSString *moviePath = [mm path];
  if (nil == moviePath) {
    NSError *noPathError = [NSError errorWithDomain:kTDAppDomain code:kUploadErrFileNotFound userInfo:nil];
    [target performSelector:selectorError withObject:nil withObject:noPathError];
    return nil;
  }

  NSData *data = [NSData dataWithContentsOfFile:moviePath];
  if (nil == data) {
    NSError *couldntReadError = [NSError errorWithDomain:kTDAppDomain code:kUploadErrCouldntReadFile userInfo:nil];
    [target performSelector:selectorError withObject:nil withObject:couldntReadError];
    return nil;
  }

  NSString *movieCategory = [mm category];
  if (nil == movieCategory) {
    NSError *noCategoryError = [NSError errorWithDomain:kTDAppDomain code:kUploadErrNoCategory userInfo:nil];
    [target performSelector:selectorError withObject:nil withObject:noCategoryError];
    return nil;
  }


  NSString *movieDescription = [mm details];
  NSArray *movieKeywords = [mm keywords];
  NSString *movieTitle = [mm title];
  if (nil == movieTitle) {
    movieTitle = [moviePath lastPathComponent];
  }


	GDataServiceGoogleYouTube *service = [self service];
  AuthCredential *cred = [self currentCredential];
  if (nil == cred) {
    NSError *noServiceError = [NSError errorWithDomain:kTDAppDomain code:kNoServiceErr userInfo:nil];
    [target performSelector:selectorError withObject:nil withObject:noServiceError];
    return nil;
  }

  if (0 == [[cred username] length] || 0 == [[cred password] length]) {
    NSError *noUsernamePasswordError = [NSError errorWithDomain:kTDAppDomain code:kNoUsernamePasswordErr userInfo:nil];
    [target performSelector:selectorError withObject:nil withObject:noUsernamePasswordError];
    return nil;
  }

  [service setUserCredentialsWithUsername:[cred username] password:[cred password]];
  GDataYouTubeMediaGroup *mediaGroup = [GDataYouTubeMediaGroup mediaGroup];

  NSString *filename = [moviePath lastPathComponent];
  if (movieTitle) {
    GDataMediaTitle *title = [GDataMediaTitle textConstructWithString:movieTitle];
    [mediaGroup setMediaTitle:title];
  }
  if (movieCategory) {
    GDataMediaCategory *category = [GDataMediaCategory mediaCategoryWithString:movieCategory];
    [category setScheme:kGDataSchemeYouTubeCategory];
    [mediaGroup addMediaCategory:category];
  }
  if (movieDescription) {
    GDataMediaDescription *desc = [GDataMediaDescription textConstructWithString:movieDescription];
    [mediaGroup setMediaDescription:desc];
  }
  if (movieKeywords) {
    GDataMediaKeywords *keywords = [GDataMediaKeywords keywordsWithStrings:movieKeywords];
    [mediaGroup setMediaKeywords:keywords];
  }

  NSString *mimeType = [GDataEntryBase MIMETypeForFileAtPath:moviePath
                                             defaultMIMEType:@"video/mp4"];

  GDataEntryYouTubeUpload *entry;
  entry = [GDataEntryYouTubeUpload uploadEntryWithMediaGroup:mediaGroup
                                                        data:data
                                                    MIMEType:mimeType
                                                        slug:filename];

  SEL progressSel = @selector(inputStream:hasDeliveredByteCount:ofTotalByteCount:);
  [service setServiceUploadProgressSelector:progressSel];

  NSURL *url = [GDataServiceGoogleYouTube youTubeUploadURLForUserID:[self account]
                                                           clientID:[self youTubeClientID]];

  [service setServiceUserData:mm];
  GDataServiceTicket *ticket;
  ticket = [service fetchYouTubeEntryByInsertingEntry:entry
                                           forFeedURL:url
                                             delegate:target
                                    didFinishSelector:selectorFinished
                                      didFailSelector:selectorError];
  [ticket setUserData:mm];
  [service setServiceUserData:nil];
  return ticket;
}


// ### TDClientAuthWindowControllerConfiguration
- (NSString *)sourceIdentifier {
  return [TDConfig() sourceIdentifier];
}

- (NSString *)docID {
  return [[mPlaylistController playlist] docID];
}

- (int)instanceNumber {
  return mInstanceNumber;
}

- (NSString *)keychainServiceName {
  return [self docID];
}

- (NSString *)account {
  return [[mPlaylistController playlist] account];
}

- (void)setAccount:(NSString *)account {
  if ( ! AreEqualOrBothNil(account, [self account])) {
    [[mPlaylistController playlist] setAccount:account];
    [self updateChangeCount:NSChangeDone];
    // gets the current account name into the window title
    NSWindow *win = [self windowForSheet];
    if (win) {
      [win setTitle:[win title]];
    }
  }
}

// used by PlaylistController if can Upload
- (AuthCredential *)currentCredential {
  AuthCredential* cred = nil;
  NSString* account = [self account];
  NSString *password = [mService password];
  if (mService && [account length] && [[mService username] isEqual:account] && [password length]) {
    cred = [AuthCredential authCredentialWithUsername:account password:password];
  } else {
    cred = [self previouslySavedCredential];
  }
  return cred;
}

- (AuthCredential *)previouslySavedCredential {
  AuthCredential* cred = nil;
  NSString* lastUsername = [self account];
  if ([lastUsername length]) {
    NSString *keychainServiceName = [self keychainServiceName];
    cred = [AuthCredential 
      authCredentialFromKeychainForService:keychainServiceName
                                  username:lastUsername];
  }
  return cred;
}

- (GDataServiceGoogleYouTube *)service {
  if (nil == mService) {
    mService = [[GDataServiceGoogleYouTube alloc] init];
    
    [mService setUserAgent:[self userAgent]];
    [mService setShouldCacheDatedData:YES];
    [mService setYouTubeDeveloperKey:[self youTubeDeveloperKey]];
    // [mService setServiceShouldFollowNextLinks:YES];
//    [GDataHTTPFetcher setIsLoggingEnabled:YES]; // for debugging
  }
  return mService;
}

- (void)setService:(GDataServiceGoogleYouTube *)service {
  [mService autorelease];
  mService = [service retain];
}


- (void)discardPreviouslySavedCredential {
  AuthCredential* cred = [self previouslySavedCredential];
  [self setAccount:nil];
  if (cred) {
    NSString *keychainServiceName = [self keychainServiceName];
    [cred removeFromKeychainForService:keychainServiceName];
  }
  [mService setUserCredentialsWithUsername:nil password:nil];
}

- (NSString *)userAgent {
  return [TDConfig() userAgent];
}

- (NSString *)youTubeDeveloperKey {
  return [TDConfig() youTubeDeveloperKey];
}

- (NSString *)youTubeClientID {
  return [TDConfig() youTubeClientID];
}

- (NSString *)ownerPath {
  return [[self fileURL] path];
}
 
@end

static NSError *AugmentError(NSError *err, NSString *errKey, NSString *suggestKey) {
  NSDictionary *dict = [err userInfo];
  NSMutableDictionary *mutDict = [[dict mutableCopy] autorelease];
  if (nil == mutDict) {
    mutDict = [NSMutableDictionary dictionary];
  }
  NSString *errS = NSLocalizedString(errKey, @"");
  if (0 < [errS length]) {
    [mutDict setObject:errS forKey:NSLocalizedDescriptionKey];
  }
  NSString *suggestS = NSLocalizedString(suggestKey, @"");
  if (0 < [suggestS length]) {
    NSDictionary *info = [err userInfo];
    NSString *path = [info objectForKey:NSFilePathErrorKey];
    if (path) {
      suggestS = [NSString stringWithFormat:suggestS, path];
    }
    [mutDict setObject:suggestS forKey:NSLocalizedRecoverySuggestionErrorKey];
  }
  NSError *result = [NSError errorWithDomain:[err domain] code:[err code] userInfo:mutDict];
  return result;
}


