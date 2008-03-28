//
//  TDModelFileRef.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
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
