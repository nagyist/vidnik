//
//  TDModelPlaylist.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDModelPlaylist.h"
#import "TDConfiguration.h"
#import "TDModelMovie.h"
#import "UndoManager+Additions.h"

static NSString * const kMoviesKey = @"movies";
static NSString * const kAccountKey = @"account";
static NSString * const kDocIDKey = @"docID";

@implementation TDModelPlaylist

+ (TDModelPlaylist *)playListWithMovie:(TDModelMovie *)modelMovie {
  if (nil == modelMovie) {
    return nil;
  }
  TDModelPlaylist *playList = [[[TDModelPlaylist alloc] init] autorelease];
  [playList addModelMovie:modelMovie];

  return playList;
}

- (id)init {
  self = [super init];
  if (self){
    mModelMovies = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void)dealloc {
  int i, iCount = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [mModelMovies objectAtIndex:i];
    [mm setDelegate:nil];
  }
  [mAccount release];
  [mDocID release];
  // mDelegate is weak.
  [mModelMovies release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  TDModelPlaylist *m = [[TDModelPlaylist allocWithZone:zone] init];
  if (m) {
    m->mAccount = [mAccount copyWithZone:zone];
    m->mDocID = [mDocID copyWithZone:zone];
    [mModelMovies autorelease];
    m->mModelMovies = [mModelMovies mutableCopyWithZone:zone];
    int i, iCount = [m->mModelMovies count];
    for (i = 0; i < iCount; ++i) {
      TDModelMovie *mm = [m->mModelMovies objectAtIndex:i];
      [mm setDelegate:m];
    }
  }
  return m;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (mModelMovies) { [coder encodeObject:mModelMovies forKey:kMoviesKey]; }
  if (mAccount) {  [coder encodeObject:mAccount forKey:kAccountKey];  }
  if (mDocID) {  [coder encodeObject:mDocID forKey:kDocIDKey];  }
}

- (id)initWithCoder:(NSCoder *)coder {
  mModelMovies = [[coder decodeObjectForKey:kMoviesKey] retain];
  int i, iCount = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [mModelMovies objectAtIndex:i];
    [mm setDelegate:self];
  }
  mAccount = [[coder decodeObjectForKey:kAccountKey] retain];
  mDocID = [[coder decodeObjectForKey:kDocIDKey] retain];
  return self;
}

// ### Attributes
- (NSString *)account {
  return mAccount;
}

- (void)setAccountPrimitive:(NSString *)account {
  [mAccount autorelease];
  mAccount = [account copy];
}

- (void)setAccount:(NSString *)account {
  [self setAccountPrimitive:account];
}

- (id)delegate {
  return mDelegate;
}

- (void)setDelegate:(id)delegate {
  if (mDelegate && nil == delegate) {
    // transitioning to nil.
    NSUndoManager *um = [[self delegate] undoManager];
    int i, iCount = [mModelMovies count];
    for (i = 0; i < iCount; ++i) {
      TDModelMovie *mm = [mModelMovies objectAtIndex:i];
      [um removeAllActionsWithTarget:mm];
    }
    [um removeAllActionsWithTarget:self];
  }
  mDelegate = delegate;
}

- (NSString *)docID {
  return mDocID;
}

- (void)verifyDocID {
  if (nil == mDocID) {
    mDocID = [[TDConfig() nextDocumentID] retain];
  }
}


- (NSArray *)modelMovies {
  return mModelMovies;
}

- (void)setModelMovies:(NSArray *)modelMovies {
  NSUndoManager *um = [[self delegate] undoManager];
  [[um prepareWithInvocationTarget:self] setModelMovies:[self modelMovies]];
  if ( ! [um isUndoingOrRedoing]) {
    [um setActionName:NSLocalizedString(@"Set Playlist", @"Undo")];
  }
  int i, iCount = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [mModelMovies objectAtIndex:i];
    [mm setDelegate:nil];
  }
  [mModelMovies autorelease];
  mModelMovies = [modelMovies mutableCopy];
  iCount = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *mm = [mModelMovies objectAtIndex:i];
    [mm setDelegate:self];
  }
  [[self delegate] playlistDidChange:self];
}

- (unsigned)modelMovieCount {
  return [mModelMovies count];
}

- (TDModelMovie *)modelMovieAtIndex:(unsigned)index {
  return [mModelMovies objectAtIndex:index];
}

- (void)addModelMovie:(TDModelMovie *)modelMovie {
  [self insertModelMovie:modelMovie atIndex:[mModelMovies count]];
}

- (void)insertModelMovie:(TDModelMovie *)modelMovie atIndex:(unsigned)index {
  NSUndoManager *um = [[self delegate] undoManager];
  [[um prepareWithInvocationTarget:self] removeModelMovieAtIndex:index];
  if ( ! [um isUndoingOrRedoing]) {
    [um setActionName:NSLocalizedString(@"Insert Movie", @"Undo")];
  }

  [[self delegate] playlistWillChange:self];
  [mModelMovies insertObject:modelMovie atIndex:index];
  [modelMovie setDelegate:self];
  [[self delegate] playlistDidChange:self];
}

- (void)removeModelMovieAtIndex:(unsigned)index {
  NSUndoManager *um = [[self delegate] undoManager];
  TDModelMovie *mm = [self modelMovieAtIndex:index];
  [um removeAllActionsWithTarget:mm];
  [[um prepareWithInvocationTarget:self] insertModelMovie:mm atIndex:index];
  if ( ! [um isUndoingOrRedoing]) {
    [um setActionName:NSLocalizedString(@"Remove Movie", @"Undo")];
  }

  [[self delegate] playlistWillChange:self];
  [mModelMovies removeObjectAtIndex:index];
  [mm setDelegate:nil];
  [[self delegate] playlistDidChange:self];
}

- (void)replaceModelMovieAtIndex:(unsigned)index withModelMovie:(TDModelMovie *)modelMovie {
  TDModelMovie *oldMovie = [self modelMovieAtIndex:index];
  if ( ! [modelMovie isEqual:oldMovie]) {
    NSUndoManager *um = [[self delegate] undoManager];
    [[um prepareWithInvocationTarget:self] replaceModelMovieAtIndex:index withModelMovie:oldMovie];
    if ( ! [um isUndoingOrRedoing]) {
      [um setActionName:NSLocalizedString(@"Replace Movie", @"Undo")];
    }

    [[self delegate] playlistWillChange:self];
    [mModelMovies replaceObjectAtIndex:index withObject:modelMovie];
    [oldMovie setDelegate:nil];
    [modelMovie setDelegate:self];
    [[self delegate] playlistDidChange:self];
  }
}

- (int)indexOfModelMovie:(TDModelMovie *)modelMovie {
  int i, iCount  = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [self modelMovieAtIndex:i];
    if ([movie isEqual:modelMovie]) {
      return i;
    }
  }
  return -1;
}


- (int)indexOfModelMovieWithPath:(NSString *)path {
  int i, iCount  = [mModelMovies count];
  for (i = 0; i < iCount; ++i) {
    TDModelMovie *movie = [self modelMovieAtIndex:i];
    if ([movie hasFilePath:path]) {
      return i;
    }
  }
  return -1;
}

- (void)modelMovieChanged:(TDModelMovie *)modelMovie userInfo:(NSMutableDictionary *)info {
  [info setObject:self forKey:@"playlist"];
  [[self delegate] modelMovieChanged:modelMovie userInfo:info];
}

- (id<MoviePerformer>)moviePerformerForMovie:(TDModelMovie *)mm {
  return [[self delegate] moviePerformerForMovie:mm];
}


- (NSString *)ownerPath {
  return [[self delegate] ownerPath];
}


@end


