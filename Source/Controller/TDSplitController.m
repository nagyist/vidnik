//
//  TDSplitController.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/6/08.
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

#import "TDSplitController.h"

enum {
  kSpltterWidth = 8,
  kLeftMinWidth = 178,
  kRightMinWidth = 544 - (kLeftMinWidth + kSpltterWidth),
};

@implementation TDSplitController

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedCoord ofSubviewAt:(int)offset {
  return kLeftMinWidth;
}

- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedCoord ofSubviewAt:(int)offset {
  return [sender frame].size.width - kSpltterWidth - kRightMinWidth;
}

- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview {
  return NO;
}

@end
