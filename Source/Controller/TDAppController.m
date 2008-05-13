//
//  TDAppController.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
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

#import "TDAppController.h"
#import "TDConfiguration.h"
#import "TDCapture.h"
#import "TDiaryDocument.h"
#import "GDataHTTPFetcher.h"
#import "GDataEntryYouTubeVideo.h"
#import "GDataHTTPFetcherLogging.h"
#import "PreferencesWindowController.h"
#import "Sparkle/SUUpdater.h"
#import "TDQTKit.h"

static int SortCategory(id a, id b, void *unused);

@interface TDAppController(PrivateMethods)
- (void)fetchCategories;
- (void)fixAccountMenuItem;
@end

@implementation TDAppController

+ (void)initialize {
  NSError *err = nil;

  // Get rid of annoying Sparkly dialog on first launch
  NSDictionary *defaults = [NSDictionary dictionaryWithObjectsAndKeys:
    [NSNumber numberWithBool:YES], @"SUHasLaunchedBefore",
    nil];
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];

  if( ! TDCaptureInit(&err)) {
    [NSApp presentError:err];
    [NSApp terminate:self];
  }
}

- (id)init {
  self = [super init];
  if (self) {
    [GDataHTTPFetcher setDefaultRunLoopModes:[NSArray arrayWithObjects:
      NSDefaultRunLoopMode, NSModalPanelRunLoopMode, NSEventTrackingRunLoopMode, nil]];
    mConfig = [[TDConfiguration alloc] init];
  }
  return self;
}

- (void)dealloc {
  [mConfig release];
  [super dealloc];
}

- (TDConfiguration *)config {
  return mConfig;
}

- (void)setConfig:(TDConfiguration *)config {
  [mConfig autorelease];
  mConfig = [config retain];
  // TODO: (oster) should probably post a config changed notification
}

- (void)awakeFromNib {
  enum {
    kTwoDaysAsSecs = 24*60*60
  };
  NSArray *categories = [[self config] categories];
  NSDate  *categoriesFetchDate = [[self config] categoriesFetchDate];
  if (nil == categories|| 
    nil == categoriesFetchDate ||
    kTwoDaysAsSecs <= ([[NSDate date] timeIntervalSinceReferenceDate] - [categoriesFetchDate timeIntervalSinceReferenceDate])) {

    [self fetchCategories];
  }
  [self fixAccountMenuItem];
  [GDataHTTPFetcher setIsLoggingEnabled:[TDConfig() isGDataHTTPLogging]];
}

- (void)applicationDidBecomeActive:(NSNotification *)notify {
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  NSArray *documents = [dc documents];
  [documents makeObjectsPerformSelector:@selector(startValidatingFilePaths)];
}

- (id)openDocumentWithContentsOfURL:(NSURL *)url 
                            display:(BOOL)isShown 
                              error:(NSError **)error {
  NSDocumentController *dc = [NSDocumentController sharedDocumentController];
  TDiaryDocument *doc = [dc documentForURL:url];

  if (doc) {
    if (isShown) {
      [doc showWindows];
    }
  } else {
    doc = [dc makeDocumentWithContentsOfURL:url ofType:@"TDoc" error:error];
    if (nil == doc) {
      doc = [dc makeDocumentWithContentsOfURL:url ofType:@"Movie" error:error];
    }
    if (doc) {
      [dc addDocument:doc];
      if ([dc shouldCreateUI]) {
        [doc makeWindowControllers];
        if (isShown) {
          [doc showWindows];
        }
      }
    }
  }
  return doc;
}

// returns YES if did re-open it.
- (BOOL)reopenPreviousDocument {

  static BOOL gIsFirstTime = YES;
  if ( ! gIsFirstTime) {
    return NO;
  }
  gIsFirstTime = NO;

  NSString *lastPath = [TDConfig() lastDocumentPath];
  if (lastPath) {
    NSError *error = nil;
    id val = [self openDocumentWithContentsOfURL:[NSURL fileURLWithPath:lastPath]  display:YES error:&error];
    if (nil == val && error) {
      // if it is essentially a file not found error, then don't bother to tell the user.
      [TDConfig() setLastDocumentPath:nil];
      if ( ! ([[error domain] isEqual:NSOSStatusErrorDomain] && [error code] == NSURLErrorCannotLoadFromNetwork)) {
        [NSApp presentError:error];
      }
    }
    return nil != val;
  }
  return NO;
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return ! [self reopenPreviousDocument];
}

#if 0 // note: this is getting called too early in the terminate cycle: 
// before the document windows close.
- (void)applicationWillTerminate:(NSNotification *)aNotification {
  [TDConfig() synchronize];
}
#endif

- (BOOL)panel:(id)sender shouldShowFilename:(NSString *)path {
  BOOL isDir = NO;

  [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
  if (isDir) {
    return YES;
  }
  // this is a kludge. Really should use [NSDocumentController's documentClassNames]'s fileExtensionsFromType
  if (NSOrderedSame == [[path pathExtension] caseInsensitiveCompare:@"vidnik"]) {
    return YES;
  }
  return [QTMovie canInitWithFile:path];
}

- (void)openDocument:(id)sender {
  NSOpenPanel *openPanel = [NSOpenPanel openPanel];

  [openPanel setDelegate:self];
  [openPanel setAllowsMultipleSelection:YES];
  
  // files are filtered through the panel:shouldShowFilename: method above
  if (NSOKButton == [openPanel runModalForTypes:nil]) {
    NSArray *urls = [openPanel URLs];
    NSError *error = nil;
    int i, iCount = [urls count];
    for (i = 0; i < iCount && nil == error; ++i) {
      NSURL *url = [urls objectAtIndex:i];
      [self openDocumentWithContentsOfURL:url display:YES error:&error];
    }
    if (error) {
      [NSApp presentError:error];
    }
  }
}


- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)path {
  NSURL *url = [NSURL fileURLWithPath:path];
  NSError *error = nil;
  return nil != [self openDocumentWithContentsOfURL:url display:YES error:&error];
}

- (IBAction)showPreferences:(id)sender {
  PreferencesWindowController* prefs = [PreferencesWindowController sharedPreferencesWindowController];
  [prefs showWindow:self];
}


- (IBAction)checkForUpdates:(id)sender {
  [mUpdater checkForUpdates:sender];
}

@end

@implementation TDAppController(PrivateMethods)

- (void)fetchCategories {
  NSURL *categoriesURL = [NSURL URLWithString:kGDataSchemeYouTubeCategory];
  NSURLRequest *request = [NSURLRequest requestWithURL:categoriesURL];
  GDataHTTPFetcher *fetcher = [GDataHTTPFetcher httpFetcherWithRequest:request];
    
  [fetcher beginFetchWithDelegate:self
                didFinishSelector:@selector(categoryFetcher:finishedWithData:)
        didFailWithStatusSelector:@selector(categoryFetcher:failedWithStatus:data:)
         didFailWithErrorSelector:@selector(categoryFetcher:failedWithError:)];
}

// The categories document looks like
//  <app:categories>
//    <atom:category term='Film' label='Film &amp; Animation'>
//      <yt:browsable />
//      <yt:assignable />
//    </atom:category>
//  </app:categories>
//
// We only want the categories which are assignable. We'll use XPath to
// select those, then get the string value of the resulting term attribute
// nodes.

- (void)categoryFetcher:(GDataHTTPFetcher *)fetcher finishedWithData:(NSData *)data {
  NSString *const path = @"app:categories/atom:category[yt:assignable]";

  NSError *error = nil;
  NSXMLDocument *xmlDoc = [[[NSXMLDocument alloc] initWithData:data
                                                       options:0
                                                         error:&error] autorelease];
  if (nil == xmlDoc) {
    NSLog(@"category fetch could not parse XML: %@", error);       
  } else {
    NSArray *nodes = [xmlDoc nodesForXPath:path
                                     error:&error];
    int i, iCount = [nodes count];
    if (0 == iCount) {
      NSLog(@"category fetch could not find nodes: %@", error);       
    } else {
      NSMutableArray *categories = [NSMutableArray array];
      for (i = 0; i < iCount; ++i) {
        NSXMLElement *category = [nodes objectAtIndex:i];
                   
        NSString *term = [[category attributeForName:@"term"] stringValue];
        NSString *label = [[category attributeForName:@"label"] stringValue];
        if (nil == label) {
          label = term;
        }
        if (nil == term) {
          term = label;
        }
        if (term) {
          [categories addObject:[NSArray arrayWithObjects:label, term, nil]];
        }
      }
      if ([categories count]) {
        [categories sortUsingFunction:SortCategory context:nil];
        NSArray *oldCategories = [[self config] categories];
        [[self config] setCategoriesFetchDate:[NSDate date]];
        if (nil == oldCategories ||  ! [categories isEqual:oldCategories]) {
          [[self config] setCategories:categories];
        }
      }
    }
  }
}

  // failed with server status
- (void)categoryFetcher:(GDataHTTPFetcher *)fetcher failedWithStatus:(int)status data:(NSData *)data {
  NSString *dataStr = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
  NSLog(@"categoryFetcher:%@ failedWithStatus:%d data:%@", fetcher, status, dataStr);       
}

  // failed with network error
- (void)categoryFetcher:(GDataHTTPFetcher *)fetcher failedWithError:(NSError *)error {
  NSLog(@"categoryFetcher:%@ failedWithError:%@", fetcher, error);       
}

// The Forget Account menu item is the alternate of the Change Account menu item, but
// since they don't have a command key equivalent, you can't set it in Interface Builder.
// We do it in code here.
- (void)fixAccountMenuItem {
  NSMenu *mainMenu = [NSApp mainMenu];
  NSArray *menuArray = [mainMenu itemArray];
  int i, iCount = [menuArray count];
  for (i = 0; i < iCount; ++i) {
    // for each main menu.
    NSMenu *menu = [[menuArray objectAtIndex:i] submenu];
    int changeIndex = [menu indexOfItemWithTarget:nil andAction:@selector(fetchCredentials:)];
    int forgetIndex = [menu indexOfItemWithTarget:nil andAction:@selector(forgetCredentials:)];
    if (0 <= changeIndex && 0 <= forgetIndex && changeIndex + 1 == forgetIndex) {
      NSMenuItem *forgetAccount = [menu itemAtIndex:forgetIndex];
      [forgetAccount setAlternate:YES];
      [forgetAccount setKeyEquivalentModifierMask:NSAlternateKeyMask];
      return; // did it, done.
    }
  }
}

- (void)showResponder:(id)sender {
  NSResponder *r = [[NSApp mainWindow] firstResponder];
  while (r) {
NSLog(@"%@", r);
    r = [r nextResponder];
  }
}

@end

static int SortCategory(id a, id b, void *unused) {
  NSArray *aa = a;
  NSArray *bb = b;
  NSComparisonResult result = [[aa objectAtIndex:0] localizedCaseInsensitiveCompare: [bb objectAtIndex:0]];
  if (NSOrderedSame != result) {
    return result;
  }
  result = [[aa objectAtIndex:1] localizedCaseInsensitiveCompare: [bb objectAtIndex:1]];
  return result;
}


