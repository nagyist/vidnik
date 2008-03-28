//
//  TDModelMovieAdditions.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/3/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDModelMovieAdditions.h"
#import "QTMovie+Async.h"
#import "String+Path.h"
#import "TDModelFileRef.h"

@interface TDModelMovie(PrivateAdditionsMethods)
- (id<MoviePerformer>)moviePerformer;
@end

@implementation TDModelMovie(Additions)
- (BOOL)canUpload {
  ModelMovieState movieState = [self movieState];
// TODO: re-validate states here?
  return movieState == kReadyToUpload && [self canRevealInFinder];
}

- (BOOL)canRevealInFinder {
  return nil != [self path];
}

- (BOOL)canRevealInBrowser {
  return 0 < [[self urlString] length];
}

// YES if path changed
- (BOOL)validateFilePathWithOwner:(NSString *)ownerPath {
  BOOL val = [mMovieFile validateFilePathWithOwner:ownerPath];
// TODO: should we match with mMovie here? 
  if (val) {
    QTMovie *movie = [self movie];
    NSURL *fileURL = [movie attributeForKey:QTMovieURLAttribute];
    if ( ! [[mMovieFile path] isEqual:[fileURL path]]) {
      QTMovie *mov = [QTMovie asyncMovieWithURL:[NSURL fileURLWithPath:[mMovieFile path]] error:nil];
      if (mov) {
        [self setMovie:mov];
      }
    }
  }
  return val;
}

- (NSString *)stringRepresentationForPasteBoard {
  NSMutableString *s = [NSMutableString string];
  NSString *title = [self title];
  if (0 < [title length]) {
    [s appendFormat:@"title:%@\n", title];
  }
  NSString *category = [self category];
  if (0 < [category length]) {
    [s appendFormat:@"category:%@\n", category];
  }
  NSArray *keywords = [self keywords];
  if (0 < [keywords count]) {
    [s appendFormat:@"keywords:%@\n", [keywords componentsJoinedByString:@" "]];
  }
  NSString *details = [self details];
  if (0 < [details length]) {
    [s appendFormat:@"description:%@\n", details];
  }
  return s;
}

- (void)updateMovieFileIfNeeded {
  [mMovie updateMovieFileIfNeeded];
}

- (void)updateReadyToUploadState {
  switch (mMovieState) {
  case kUploading:
  case kUploaded:
    return;
  default:
    break;
  }
  int isReady = 0;
  if ([self canRevealInFinder]) { isReady |= kHasMovieFile; }
  if ([[self category] length]) { isReady |= kHasCategory; }
  if ([[self details] length]) { isReady |= kHasDetails; }
  if ([[self keywords] count]) { isReady |= kHasKeywords; }
  if ([[self title] length]) { isReady |= kHasTitle; }
  if (mMovie) { isReady |= kHasMovie; } // must be after canRevealInFinder.
  if (mMovieState <= kReadyToUpload) {
      mMovieState = isReady;
  } else switch(mMovieState) {
  case kUploadingCancelled:
  case kUploadingErrored:
    if ( ! isReady) {
      mMovieState = kNotReadyToUpload;
    }
    break;
    
  default:
    break;
  }
}

// ### TDModelUploadingAction callback. argument is progress cell.
#pragma mark -
#pragma mark ### TDModelUploadingAction support

// argument is progress cell.
- (void)userCancelledUploading:(id)sender {
  [[self delegate] userCancelledUploading:self];
}


// ### Applescript support
#pragma mark -
#pragma mark ### Applescript support

- (id)handlePauseScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  [[self moviePerformer] pause:nil];
  return nil;
}

- (id)handlePlayScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  [[self moviePerformer] play:nil];
  return nil;
}

- (id)handleRecordScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  [[self moviePerformer] record:nil];
  return nil;
}


- (id)handleSelectScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  NSDictionary *arguments = [command evaluatedArguments];
  NSNumber *startN = [arguments objectForKey:@"StartTime"];
  NSNumber *endN = [arguments objectForKey:@"StopTime"];
  if (startN && endN) {
    double startF = [startN doubleValue];
    double endF = [endN doubleValue];
    [[self moviePerformer] setSelectionStart:startF end:endF];
  }
  return nil;
}

- (id)handleSelectAllScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  [[self moviePerformer] selectAll:nil];
  return nil;
}

- (id)handleSelectNoneScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  [[self moviePerformer] selectNone:nil];
  return nil;
}

- (id)handleStepForwardScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  [[self moviePerformer] step:1];
  return nil;
}

- (id)handleStepBackwardScriptCommand:(NSScriptCommand *)command {
  [[self delegate] setSelectedModelMovie:self];
  [[self moviePerformer] step:-1];
  return nil;
}

- (id)handleStopScriptCommand:(NSScriptCommand *)command {
  [[self moviePerformer] stop:nil];
  return nil;
}


- (NSScriptObjectSpecifier *)objectSpecifier {
  NSScriptObjectSpecifier *containerSpecifier = [[self delegate] objectSpecifier];
  return [[[NSIndexSpecifier alloc] initWithContainerClassDescription:[containerSpecifier keyClassDescription]
               containerSpecifier:containerSpecifier
                              key:@"movies" 
                            index:[self orderedIndex]] autorelease];
}

- (int)orderedIndex {
  return [[self delegate] indexOfModelMovie:self];
}

- (int)orderedID {
  return (intptr_t) self;
}

- (OSType)recordedState {
  return 'pasd';
}

- (long long)dataSize {
  NSNumber *n = [[self movie] attributeForKey:QTMovieDataSizeAttribute];
  return [n longLongValue];
}

- (double)selectionDuration {
  NSValue *selValue = [[self movie] attributeForKey:QTMovieSelectionAttribute];
  if (selValue) {
    QTTimeRange range = [selValue QTTimeRangeValue];
    NSTimeInterval secs = 0;
    if (QTGetTimeInterval(range.duration, &secs)) {
      return secs;
    }
  }
  return 0;
}

- (void)setSelectionDuration:(double)selectionDuration {
  NSValue *selValue = [[self movie] attributeForKey:QTMovieSelectionAttribute];
  if (selValue) {
    QTTimeRange range = [selValue QTTimeRangeValue];
    [[self movie] setAttribute:[NSValue valueWithQTTimeRange:range]  forKey:QTMovieSelectionAttribute];

    NSTimeInterval selStart;
    if (QTGetTimeInterval(range.time, &selStart)) {
      NSTimeInterval duration = [self duration];
      if (duration < selStart + selectionDuration) {
        selectionDuration = duration - selStart;
      }
    }
    range.duration = QTMakeTimeWithTimeInterval(selectionDuration);
    [[self movie] setAttribute:[NSValue valueWithQTTimeRange:range]  forKey:QTMovieSelectionAttribute];
  }
}


- (double)selectionStart {
  NSValue *selValue = [[self movie] attributeForKey:QTMovieSelectionAttribute];
  if (selValue) {
    QTTimeRange range = [selValue QTTimeRangeValue];
    NSTimeInterval secs = 0;
    if (QTGetTimeInterval(range.time, &secs)) {
      return secs;
    }
  }
  return 0;
}

- (void)setSelectionStart:(double)selectionStart {
  if (selectionStart < 0) {
    // we could throw a param error exception here.
    return;
  }
  NSTimeInterval duration = [self duration];
  if (duration < selectionStart) {
    // we could throw a param error exception here.
    return;
  }
  NSValue *selValue = [[self movie] attributeForKey:QTMovieSelectionAttribute];
  if (selValue) {
    QTTimeRange range = [selValue QTTimeRangeValue];
    range.time = QTMakeTimeWithTimeInterval(selectionStart);
    NSTimeInterval selDuration;
    if (QTGetTimeInterval(range.duration, &selDuration)) {
      if (duration < selectionStart + selDuration ){
        range.duration = QTMakeTimeWithTimeInterval(duration - selectionStart);
      }
    }
    [[self movie] setAttribute:[NSValue valueWithQTTimeRange:range] forKey:QTMovieSelectionAttribute];
  }
}


- (double)selectionEnd {
  return [self selectionStart] + [self selectionDuration];
}

- (void)setSelectionEnd:(double)selectionEnd { 
  double start = [self selectionStart];
  if (selectionEnd < start) {
    selectionEnd = start;
  }
  [self setSelectionDuration:(selectionEnd - start)];
}


- (double)duration {
  QTTime duration = [[self movie] duration];
  NSTimeInterval secs = 0;
  if (QTGetTimeInterval(duration, &secs)) {
    return secs;
  }
  return 0;
}

- (NSURL *)fileURL {
  QTMovie *movie = [self movie];
  if (movie) {
    return [movie attributeForKey:QTMovieURLAttribute];
  }
  return nil;
}


@end

@implementation TDModelMovie(PrivateAdditionsMethods)

- (id<MoviePerformer>)moviePerformer {
  return [[self delegate] moviePerformerForMovie:self];
}

@end
