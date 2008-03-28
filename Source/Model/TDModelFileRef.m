//
//  TDModelFileRef.m
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDModelFileRef.h"

static NSString * const kAliasKey = @"alias";
static NSString * const kPathKey = @"path";

// convert a filePath string to a pointer to an FSRef, or nil on failure.
static FSRef *OwnerRef(NSString *ownerPath, FSRef *buffer);


@interface TDModelFileRef(PrivateMethods)

// ownerPath may be nil
- (void)setPath:(NSString *)path owner:(NSString *)ownerPath;
- (void)aliasRelease;
@end

@implementation TDModelFileRef

+ (TDModelFileRef *)modelFileRefWithPath:(NSString *)path ownerPath:(NSString *)ownerPath {
  TDModelFileRef *ref = [[[TDModelFileRef alloc] init] autorelease];
  [ref setPath:path owner:ownerPath];
  return ref;
}



- (void)dealloc {
  [self aliasRelease];
  [mPath release];
  [super dealloc];
}

- (id)copyWithZone:(NSZone *)zone {
  TDModelFileRef *m = [[TDModelFileRef allocWithZone:zone] init];
  m->mPath = [mPath copyWithZone:zone];
  Handle h = (Handle)mAlias;
  if (mAlias && noErr == HandToHand(&h)) {
    m->mAlias = (AliasHandle) h;
  }
  return m;
}

- (void)encodeWithCoder:(NSCoder *)coder {
  if (mAlias) {
    SInt8 state = HGetState( (Handle) mAlias);
    HLock( (Handle) mAlias);
    [coder encodeBytes: (const uint8_t *) *mAlias length: GetAliasSize(mAlias) forKey:kAliasKey];
    HSetState((Handle) mAlias, state);
  }
  if (mPath) { [coder encodeObject:mPath forKey:kPathKey]; }
}

- (id)initWithCoder:(NSCoder *)coder {
  unsigned len = 0;
  const uint8_t *p = [coder decodeBytesForKey:kAliasKey returnedLength:&len];
  if (p && len < 20000) {
    OSErr e = PtrToHand(p, (Handle *) &mAlias, len);
    if (noErr != e) {
    }
  }
  mPath = [[coder decodeObjectForKey:kPathKey] retain];
  return self;
}


- (AliasHandle)alias {
  return mAlias;
}

- (NSString *)path {
  return mPath;
}

// two file paths are equivalent if they reference the same file, where
// "same file" means same device, same inode.
- (BOOL)hasFilePath:(NSString *)path {
  if ([mPath isEqual:path]) {
    return YES;
  }
  NSFileManager *fm = [NSFileManager defaultManager];
  NSDictionary *selfDict = [fm fileAttributesAtPath:mPath traverseLink:YES];
  NSDictionary *pathDict = [fm fileAttributesAtPath:path traverseLink:YES];
  return selfDict && pathDict && 
    [[selfDict objectForKey:NSFileDeviceIdentifier] isEqual:[pathDict objectForKey:NSFileDeviceIdentifier]] &&
    [[selfDict objectForKey:NSFileSystemFileNumber] isEqual:[pathDict objectForKey:NSFileSystemFileNumber]];
}

// attempt to resolve alias and compare to path. if not match, but can resolve
// alias, returns YES.
- (BOOL)validateFilePathWithOwner:(NSString *)ownerPath {
  FSRef ref;
  FSRef ownerRef;
  FSRef *ownerRefp = OwnerRef(ownerPath, &ownerRef);
  Boolean isChanged = NO;
  UInt8 buffer[PATH_MAX];
  if (mAlias && (
    noErr == FSResolveAlias(ownerRefp , mAlias, &ref, &isChanged) ||
    noErr == FSResolveAlias(nil, mAlias, &ref, &isChanged)) && isChanged &&
    noErr == FSRefMakePath(&ref, buffer, PATH_MAX)) {

    NSString *path = [NSString stringWithUTF8String:(const char*)buffer];
    [mPath release];
    mPath = [path retain];
    return YES;
  }
  return NO;
}

@end
@implementation TDModelFileRef(PrivateMethods)

// if owner is non-nil, we make a relative aliasHandle.
- (void)setPath:(NSString *)path owner:(NSString *)ownerPath {
  if (mPath != path) {
    [mPath autorelease];
    mPath = [path copy];
    Boolean isDir = NO;
    FSRef ref;
    FSRef ownerRef;
    FSRef *ownerRefp = OwnerRef(ownerPath, &ownerRef);
    AliasHandle ah = nil;
    if (path && 
      noErr == FSPathMakeRef((const unsigned char *)[path fileSystemRepresentation], &ref, &isDir) &&
      noErr == FSNewAlias(ownerRefp, &ref, &ah)) {
      [self aliasRelease];
      mAlias = ah;
     }
  }
}

- (void)aliasRelease {
  if (mAlias) {
    DisposeHandle( (Handle) mAlias);
    mAlias = nil;
  }
}
@end

// convert a filePath string to a pointer to an FSRef, or nil on failure.
static FSRef *OwnerRef(NSString *ownerPath, FSRef *buffer) {
  Boolean isDir = NO;
  if (ownerPath &&
    noErr == FSPathMakeRef((const unsigned char *)[ownerPath fileSystemRepresentation], buffer, &isDir)) {

    return buffer;
  }
  return nil;
}
