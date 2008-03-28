//
//  MovieView.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/17/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "MovieView.h"
#import "QTMovie+Async.h"


@implementation MovieView

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  SEL action = [anItem action];
  QTMovie *movie;
  if (action == @selector(trim:) ||
      action == @selector(selectAll:)) {
    if( ! [self isHidden] && 
      nil != (movie = [self movie]) &&
      [movie hasAttributes]) {

      QTTime tiny = QTMakeTimeWithTimeInterval(1/60.);
      QTTime selectionDuration = [movie selectionDuration];
      QTTime duration = [movie duration];
      return (NSOrderedAscending == QTTimeCompare(tiny, selectionDuration) &&
            NSOrderedAscending == QTTimeCompare(selectionDuration, duration));
    }
    return NO;
  }
  return YES;
}

- (IBAction)trim:(id)sender {
  QTMovie *movie = [self movie];
  [movie registerNeedsUpdate];
  [super trim:sender];
}
@end
