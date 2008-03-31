//
//  TDModelFileRef.h
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

#import <Cocoa/Cocoa.h>

// we keep the path, but also, when the path is set, we keep the aliasHandle.
// this gives us some ability to find the file if it is moved.
@interface TDModelFileRef : NSObject<NSCoding, NSCopying> {
 @private
  NSString    *mPath;
  AliasHandle mAlias;
}
// ownerPath may be nil.
+ (TDModelFileRef *)modelFileRefWithPath:(NSString *)path ownerPath:(NSString *)ownerPath;
- (AliasHandle)alias;

- (NSString *)path;
    
- (BOOL)hasFilePath:(NSString *)path;

// attempt to resolve alias and compare to path. if not match, but can resolve
// alias, returns YES. Owner is document, for relative path lookup.
- (BOOL)validateFilePathWithOwner:(NSString *)ownerPath;
@end
