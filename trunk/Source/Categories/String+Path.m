//
//  String+Path.m
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/14/08.
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

#import "String+Path.h"


@implementation NSString (TDStringPathAdditions)
- (BOOL)directoryPathExists {
  
  NSFileManager* fileMgr = [NSFileManager defaultManager];
  
  BOOL isDir;
  BOOL doesExist = [fileMgr fileExistsAtPath:self isDirectory:&isDir] && isDir;
  return doesExist;
}

- (BOOL)isInTrash {
  NSRange r = [self rangeOfString:@"/.Trash/"];
  return NSNotFound != r.location;
}

- (BOOL)isWritableFolderPath {
  NSFileManager *fm = [NSFileManager defaultManager];
  BOOL isDir = NO;
  BOOL isWritableFolder = [fm fileExistsAtPath:self isDirectory:&isDir] && 
                          isDir &&
                          [fm isWritableFileAtPath:self];
  return isWritableFolder;
}

+ (NSString *)stringWithPathForFolder:(OSType)theFolderType 
                             inDomain:(short)theDomain
                             doCreate:(BOOL)doCreate {
  
  NSString *folderPath = nil;
  FSRef folderRef;
  
  OSErr err = FSFindFolder(theDomain, theFolderType, doCreate, &folderRef);
  if (err == noErr) {
    
    CFURLRef folderURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &folderRef);
    if (folderURL) {
      
      folderPath = (NSString *)CFURLCopyFileSystemPath(folderURL, kCFURLPOSIXPathStyle);
      [folderPath autorelease];
      
      CFRelease(folderURL);
    }
  }
  return folderPath;
}

+ (NSString *)stringWithPathForFolder:(OSType)theFolderType 
                        subfolderName:(NSString *)subfolderName
                             inDomain:(short)theDomain
                             doCreate:(BOOL)doCreate {
  NSString *resultPath = nil;
  NSString *subdirPath = nil;
  NSString *parentFolderPath = [self stringWithPathForFolder:theFolderType
                                                    inDomain:theDomain
                                                    doCreate:doCreate];
  if (parentFolderPath) {
    
    // find the path to the subdirectory
    subdirPath = [parentFolderPath stringByAppendingPathComponent:subfolderName];
    
    if ([subdirPath directoryPathExists]) {
      // it already exists
      resultPath = subdirPath;
    } else if (doCreate) {
      
      // create the subdirectory with the parent folder's attributes
      NSFileManager* fileMgr = [NSFileManager defaultManager];
      NSDictionary* attrs = [fileMgr fileAttributesAtPath:parentFolderPath
                                             traverseLink:YES];
      if ([fileMgr createDirectoryAtPath:subdirPath
                              attributes:attrs]) {
        resultPath = subdirPath;
      }
    }
  }
  return resultPath;
}

- (NSString *)stringByReplacingString:(NSString *)oldString
                           withString:(NSString *)newString {
  // If |oldString| was nil, then do nothing and return |self|
  //
  // We do the retain+autorelease dance here because of this use case:
  //   NSString *s1 = [[NSString alloc] init...];
  //   NSString *s2 = [s1 stringByReplacingString:@"foo" withString:@"bar"];
  //   [s1 release];  // |s2| still needs to be valid after this line
  if (!oldString)
    return [[self retain] autorelease];
  
  // If |newString| is nil we want it to be treated as if @"" was specified
  // ... effectively removing |oldString| from self
  if (!newString)
    newString = @"";
  
  NSArray *componentsMinusOld = [self componentsSeparatedByString:oldString];
  return [componentsMinusOld componentsJoinedByString:newString];
}

- (NSArray *)componentsSeparatedByCharacterSet:(NSCharacterSet *)set {
  if (nil == set) {
    return [NSArray arrayWithObject:self];
  }
  NSMutableArray *val = [NSMutableArray array];
  NSScanner *scan = [[[NSScanner alloc] initWithString:self] autorelease];
  [scan setCharactersToBeSkipped:[[[NSCharacterSet alloc] init] autorelease]];
  unsigned int scanPos = NSNotFound;
  while ( ! [scan isAtEnd]) {
    NSString *segment = nil;
    if ([scan scanUpToCharactersFromSet:set intoString:&segment]) {
      scanPos = [scan scanLocation];
      if (0 < [segment length]) {
        [val addObject:segment];
      }
    }
    if ([scan scanCharactersFromSet:set intoString:nil] ) {
      scanPos = [scan scanLocation];
    } else {
      break;
    }
  }
  if (scanPos < [self length]) {
    [val addObject:[self substringFromIndex:scanPos]];
  }
  return val;
}


- (NSComparisonResult)comparePathAsFinder:(NSString *)otherPath {
  NSString *selfFileName = [self lastPathComponent];
  NSString *otherFileName = [otherPath lastPathComponent];
  NSComparisonResult val = NSOrderedSame;
  if (selfFileName) {
    val = [selfFileName compareFilenameAsFinder:otherFileName];
  }
  if (NSOrderedSame == val) {
    val = [selfFileName compare:otherFileName];
  }
  return val;
}


- (NSComparisonResult)compareFilenameAsFinder:(NSString *)otherFilename {
  static int options = NSCaseInsensitiveSearch |
            NSNumericSearch
#if defined(MAC_OS_X_VERSION_10_5) &&  MAC_OS_X_VERSION_10_5 <= MAC_OS_X_VERSION_MAX_ALLOWED
            | NSDiacriticInsensitiveSearch |
            NSForcedOrderingSearch |
            NSWidthInsensitiveSearch
#endif
            ;
  NSComparisonResult val = [self compare:otherFilename  
    options:options
      range:NSMakeRange(0, [self length]) 
     locale:[NSLocale currentLocale]];
  if (NSOrderedSame == val && [self length] < [otherFilename length]) {
    val = NSOrderedAscending;
  }
  return val;
}


@end
