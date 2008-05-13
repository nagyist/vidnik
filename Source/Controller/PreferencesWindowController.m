//
//  PreferencesWindowController.m
//  Vidnik
//
//  Created by David Oster on 5/13/08.
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

#import "PreferencesWindowController.h"

PreferencesWindowController* gPreferencesController = nil;

@implementation PreferencesWindowController

+ (PreferencesWindowController *)sharedPreferencesWindowController {
  if (nil == gPreferencesController) {
    gPreferencesController = [[PreferencesWindowController alloc] init];
  }  
  return gPreferencesController;
}

- (id)init {  
  self = [self initWithWindowNibName:@"Preferences"];
  if (self != nil) {
    [self setWindowFrameAutosaveName:@"PreferencesWindow"];
  }
  return self;
}

- (void)windowWillClose:(NSNotification *)note {
  [self autorelease];
  gPreferencesController = nil;
}

@end
