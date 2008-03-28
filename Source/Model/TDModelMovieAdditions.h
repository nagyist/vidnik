//
//  TDModelMovieAdditions.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/3/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDModelMovie.h"


@interface TDModelMovie(Additions)
- (BOOL)canUpload;

- (void)updateReadyToUploadState;

- (BOOL)canRevealInFinder;

- (BOOL)canRevealInBrowser;

- (NSString *)stringRepresentationForPasteBoard;

// YES if path changed
- (BOOL)validateFilePathWithOwner:(NSString *)ownerPath;

// ### TDModelUploadingAction callback. argument is progress cell.
- (void)userCancelledUploading:(id)sender;

// ### Applescript support

- (id)handlePauseScriptCommand:(NSScriptCommand *)command;
- (id)handlePlayScriptCommand:(NSScriptCommand *)command;
- (id)handleRecordScriptCommand:(NSScriptCommand *)command;
- (id)handleSelectScriptCommand:(NSScriptCommand *)command;
- (id)handleSelectAllScriptCommand:(NSScriptCommand *)command;
- (id)handleSelectNoneScriptCommand:(NSScriptCommand *)command;
- (id)handleStepBackwardScriptCommand:(NSScriptCommand *)command;
- (id)handleStepForwardScriptCommand:(NSScriptCommand *)command;


- (NSScriptObjectSpecifier *)objectSpecifier;

- (long long)dataSize;
- (double)duration;
- (NSURL *)fileURL;
- (int)orderedIndex;
- (int)orderedID;
- (OSType)recordedState;
- (double)selectionDuration;
- (void)setSelectionDuration:(double)selectionDuration;

- (double)selectionStart;
- (void)setSelectionStart:(double)selectionStart;

- (double)selectionEnd;
- (void)setSelectionEnd:(double)selectionEnd;

@end
