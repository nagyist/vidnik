//
//  MovieView.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/17/08.
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

#import "MovieView.h"
#import "QTMovie+Async.h"


@implementation MovieView

- (BOOL)validateMenuItem:(NSMenuItem *)anItem {
  SEL action = [anItem action];
  QTMovie *movie;
  if (@selector(trim:) == action ||
      @selector(selectAll:) == action) {
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
