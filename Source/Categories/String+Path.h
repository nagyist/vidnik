//
//  String+Path.h
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

#import <Cocoa/Cocoa.h>

@interface NSString (TDStringPathAdditions)
///  Test if a path exists for a directory.
- (BOOL)directoryPathExists;

/// True if the file is in the trash.
- (BOOL)isInTrash;

/// True if this path exists, is a folder, is writable, is not in Trash, is
/// not a Package.
- (BOOL)isWritableFolderPath;

/// Create a path to a folder located with FindFolder
//
/// Args:
///   theFolderType: one of the folder types in Folders.h 
///                  (kPreferencesFolderType, etc)
///   theDomain: one of the domains in Folders.h (kLocalDomain, kUserDomain, etc)
///   doCreate: create the folder if it does not already exist
///
/// Returns:
///   full path to folder, or nil if the folder doesn't exist or can't be created
///
+ (NSString *)stringWithPathForFolder:(OSType)theFolderType 
                             inDomain:(short)theDomain 
                             doCreate:(BOOL)doCreate;


/// Create a path to a folder inside a folder located with FindFolder
//
/// Args:
///   theFolderType: one of the folder types in Folders.h 
///                  (kPreferencesFolderType, etc)
///   subfolderName: name of directory inside the Apple folder to be located or created
///   theDomain: one of the domains in Folders.h (kLocalDomain, kUserDomain, etc)
///   doCreate: create the folder if it does not already exist
///
/// Returns:
///   full path to subdirectory, or nil if the folder doesn't exist or can't be created
///
+ (NSString *)stringWithPathForFolder:(OSType)theFolderType 
                        subfolderName:(NSString *)subfolderName
                             inDomain:(short)theDomain
                             doCreate:(BOOL)doCreate;  

// Similar to the 10.5 only method: stringByReplacingOccurrencesOfString:withString:
- (NSString *)stringByReplacingString:(NSString *)oldString
                           withString:(NSString *)newString;

// Similar to the 10.5 only method: componentsSeparatedByCharactersInSet:
- (NSArray *)componentsSeparatedByCharacterSet:(NSCharacterSet *)set;

- (NSComparisonResult)comparePathAsFinder:(NSString *)otherPath;

- (NSComparisonResult)compareFilenameAsFinder:(NSString *)otherFilename;
@end
