//
//  TDMovieAttributesController.m
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

#import "TDMovieAttributesController.h"
#import "Array+Unique.h"
#import "String+Path.h"
#import "TDConfiguration.h"
#import "TDModelMovie.h"

@interface NSTextField(TDMovieAttributesControllerAdditions)
- (BOOL)needsState;
- (void)setNeedsState:(BOOL)inNeed;
@end

@implementation NSTextField(TDMovieAttributesControllerAdditions)
- (BOOL)needsState {
  return [[self stringValue] hasPrefix:@"* "];
}

- (void)setNeedsState:(BOOL)inNeed {
  if (inNeed != [self needsState]) {
    if (inNeed) {
      [self setTextColor:[NSColor redColor]];
      [self setStringValue:[@"* " stringByAppendingString:[self stringValue]]];
    } else {
      [self setTextColor:[NSColor blackColor]];
      [self setStringValue:[[self stringValue] substringFromIndex:2]];
    }
  }
}
@end


@interface TDMovieAttributesController(PrivateMethods)
- (void)categoriesDidChange:(NSNotification *)unused;
- (void)setCategory:(NSString *)category;
- (void)updateEnables;
@end

@implementation TDMovieAttributesController

- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  [mMovie release];
  [super dealloc];
}


- (void)awakeFromNib {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc addObserver:self selector:@selector(categoriesDidChange:) name:kCategoriesDidChange object:nil];

  [self categoriesDidChange:nil];
  [self updateEnables];
}

- (IBAction)categoryChanged:(id)unused {
  NSString *category = [self category];
  if (category) {
    [mMovie setCategory:category];
  }
}

- (NSUndoManager *)undoManager {
  return [[self delegate] undoManager];
}


- (NSString *)stringFromNeeds:(ModelMovieState)state {
  NSMutableString *s = [NSMutableString string];
  NSString *item;
  typedef struct Needs {
    int bit;
    NSString *name;
  }Need;
  static const Need needs[] = {
    {kHasMovieFile|kHasMovie, @"NeedsMovie"},
    {kHasTitle, @"NeedsTitle"},
    {kHasCategory, @"NeedsCategory"},
    {kHasKeywords, @"NeedsKeyword"},
    {kHasDetails, @"NeedsDetails"},
    {0, nil}
  };
  for (const Need *n = needs; n->name; ++n) {
    if (n->bit != (state & n->bit)) {
      item = NSLocalizedString(n->name, @"needs item");
      if (0 < [item length]) {
        if (0 < [s length]) { [s appendString:@", "];}
        [s appendString:item];
      }
    }
  }
  return [NSLocalizedString(@"NeedsPrefix", "needs item") stringByAppendingString:s];
}

- (NSString *)stateString:(ModelMovieState)state {
  NSString *s = @"";
  switch (state) {
  default:  s = [self stringFromNeeds:state];   break;
  case kNotReadyToUpload:  s = NSLocalizedString(@"NotReadyToUpload", @""); break;
  case kReadyToUpload:
    if ([[self delegate] account]) {
       s = NSLocalizedString(@"NotUploaded", @"");
    } else {  
      s = NSLocalizedString(@"NeedsAccount", @"");
    }
    break;
  case kUploadPreprocessing: s = NSLocalizedString(@"UploadPreprocessing", @""); break;
  case kUploaded:          s = NSLocalizedString(@"Uploaded", @""); break;
  case kUploading:         s = NSLocalizedString(@"Uploading", @""); break;
  case kUploadingCancelled: s = NSLocalizedString(@"UploadingCancelled", @""); break;
  case kUploadProcessing:  s = NSLocalizedString(@"UploadingProcessing", @""); break;
  case kUploadingErrored:  s = NSLocalizedString(@"UploadingErrored", @""); break;
  }
  return s;
}

// for the missing fields, set their titles to the "needs" state
- (void)setLegendStatus:(ModelMovieState)movieState {
  int needBits = kReadyToUpload;
  switch (movieState) {
  default:
    needBits = (kReadyToUpload & (int) movieState);
    break;
  case kUploadPreprocessing:
  case kUploading:
  case kUploaded:
  case kUploadingCancelled:
  case kUploadProcessing:
  case kUploadingErrored:
    break;
  }
  [mTitleLegend setNeedsState:(0 == (kHasTitle & needBits))];
  [mKeywordsLegend setNeedsState:(0 == (kHasKeywords & needBits))];
  [mDescriptionLegend setNeedsState:(0 == (kHasDetails & needBits))];
  [mCategoryLegend setNeedsState:(0 == (kHasCategory & needBits))];
}


// ### Atrributes
#pragma mark -
#pragma mark ### Atrributes

- (void)setModelMovie:(TDModelMovie *)modelMovie {
  [mMovie autorelease];
  mMovie = [modelMovie retain];

  NSString *s = [modelMovie title];
  [mTitle setStringValue:(s ? s : @"")];
  NSString *keywords = [[modelMovie keywords] componentsJoinedByString:@" "];
  [mKeywords setStringValue:(keywords ? keywords : @"")];

  s = [modelMovie details];
  [mDescription setString:(s ? s : @"")];

  [self setCategory:[mMovie category]];
  [self setState:[modelMovie movieState]];
  [self updateEnables];
}

- (NSString *)category {
  NSMenuItem *item = [mCategory selectedItem];
  return [item representedObject];
}

- (NSArray *)keywords {
  static NSMutableCharacterSet *seps = nil;
  if (nil == seps) {
    seps = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
    [seps addCharactersInString:@","];
  }
  return [[[mKeywords stringValue] componentsSeparatedByCharacterSet:seps] unique];
}

- (NSString *)details {
  return [mDescription string];
}

- (void)setDetails:(NSString *)details {
  [mDescription setString:[[details copy] autorelease]];
}

- (NSString *)status {
  return [mStatus stringValue];
}

- (void)setStatus:(NSString *)status {
  [mStatus setStringValue:status];
}

- (void)setState:(ModelMovieState)movieState {
  [self setStatus:[self stateString:movieState]];
  [self setLegendStatus:movieState];
}



- (NSString *)title {
  return [mTitle stringValue];
}

- (void)setTitle:(NSString *)title {
  [mTitle setStringValue:title];
}

- (id)delegate {
  return mDelegate;
}

- (void)setDelegate:(id)delegate {
  mDelegate = delegate;
}

- (void)modelMovieChanged:(TDModelMovie *)mm userInfo:(NSMutableDictionary *)info {
  if (mm && mm == mMovie) {
    NSUndoManager *um = [self undoManager];
    BOOL wasEnabled = [um isUndoRegistrationEnabled];
    [um disableUndoRegistration];
    NSString *setter = [info objectForKey:@"setter"];
    if([setter isEqual:@"setTitle:"]) {
      NSString *title = [mMovie title];
      if ( ! [title isEqual:[self title]]) {
        [self setTitle:title];
      }
    } else if([setter isEqual:@"setCategory:"]) {
      [self setCategory:[mMovie category]];
    } else if([setter isEqual:@"setKeywords:"]) {
      NSString *keywords = [[mMovie keywords] componentsJoinedByString:@" "];
      keywords = (keywords ? keywords : @"");
      if ( ! [keywords isEqual:[mKeywords stringValue]]) {
        [mKeywords setStringValue:keywords];
      }
    } else if([setter isEqual:@"setDetails:"]) {
      NSString *details = [mMovie details];
      if ( ! [details isEqual:[self details]]) {
        [self setDetails:details];
      }
    }
    [self setState:[mMovie movieState]];
    if (wasEnabled) {
      [um enableUndoRegistration];
    }
  }
}

// we will be called back through this method. so we define it even though it does nothing.
- (void)qtMovieChanged:(QTMovie *)movie userInfo:(NSMutableDictionary *)info {
}

// setting the nextKeyView in I.B. did not seem to stick.
- (BOOL)textView:(NSTextView *)text doCommandBySelector:(SEL)sel {
  BOOL didHandle = NO;
  if (text == mDescription) {
    if (@selector(insertTab:) == sel) {
      [[text window] makeFirstResponder:mTitle];
      didHandle = YES;
    } else if (@selector(insertBacktab:) == sel) {
      [[text window] makeFirstResponder:mKeywords];
      didHandle = YES;
    } 
  }
  return didHandle;
}

@end

@implementation TDMovieAttributesController(PrivateMethods)


- (void)categoriesDidChange:(NSNotification *)unused {
  NSString *selectedTerm =  [[mCategory selectedItem] representedObject];
  [mCategory removeAllItems];
  NSMenu *menu = [mCategory menu];
  NSArray *categories = [TDConfig() categories];
  int i, iCount = [categories count];
  for (i = 0; i < iCount; ++i) {
    NSArray *category = [categories objectAtIndex:i];
    NSString *term = [category objectAtIndex:1];
    NSString *label = NSLocalizedString(term, @"Localized Category");
    NSMenuItem *item = [menu addItemWithTitle:label
                                       action:nil
                                keyEquivalent:@""];
    [item setRepresentedObject:term];
  }
  // attempt to restore selection
  int idx = -1;
  if (nil == selectedTerm) {
    selectedTerm = [TDConfig() defaultCategoryTerm];
  }
  if (selectedTerm && 0 <= (idx = [mCategory indexOfItemWithRepresentedObject:selectedTerm])) {
    [mCategory selectItemAtIndex:idx];
  }
}

- (void)textDidChange:(NSNotification *)notify {
  NSText *text = [notify object];
  if (text == mDescription) {
    [mMovie setDetails:[self details]];
  }
}


- (void)controlTextDidChange:(NSNotification *)notify {
  NSControl *cont = [notify object];

  if (cont == mTitle) {
    [mMovie setTitle:[self title]];
  } else if (cont == mKeywords) {
    [mMovie setKeywords:[self keywords]];
  }
}

// set the U.I. called in response to model changes from setters, notifiers
- (void)setCategory:(NSString *)category {
  if (category) {
    int index = [mCategory indexOfItemWithRepresentedObject:category];
    if (0 <= index) {
      [mCategory selectItemAtIndex:index];
    }
  }
}

- (void)updateEnables {
  [mTitle setEnabled:(nil != mMovie)];
  [mKeywords setEnabled:(nil != mMovie)];
  [mDescription setEditable:(nil != mMovie)];
  [mCategory setEnabled:(nil != mMovie)];
}


@end
