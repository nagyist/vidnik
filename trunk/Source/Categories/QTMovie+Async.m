//
//  QTMovie+Async.m
//  Vidnik
//
//  Created by David Phillip Oster on 3/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "QTMovie+Async.h"

static NSMutableDictionary *gNeedsUpdateDict = nil;

@interface QTMovie(AsyncLoadingPrivate)
// true if duration is not same as when read.
- (BOOL)needsUpdate;
@end

@implementation QTMovie(AsyncLoading)

+ (QTMovie *)asyncMovieWithURL:(NSURL *)url error:(NSError **)errorp {
  NSDictionary *attrib = [NSDictionary dictionaryWithObjectsAndKeys:
    url, QTMovieURLAttribute,
    [NSNumber numberWithBool:YES], QTMovieOpenAsyncOKAttribute,
    nil];
  return [QTMovie movieWithAttributes:attrib error:errorp];
}

- (BOOL)hasAttributes {
  NSNumber *readState = [self attributeForKey:QTMovieLoadStateAttribute];
  if (readState) {
    long readStateN = [readState longValue];
    return QTMovieLoadStateLoaded <= readStateN;
  }
  return YES;
}

- (void)updateMovieFileIfNeeded {
  if ([self needsUpdate]) {
    if ([self canUpdateMovieFile]) {
      [self updateMovieFile];
    }
    [self unregisterNeedsUpdate];
  }
}


// call before trim. if we don't have an initial duration, then add to our assoc table.
- (void)registerNeedsUpdate {
  if (nil == gNeedsUpdateDict) {
    gNeedsUpdateDict = [[NSMutableDictionary alloc] init];
    NSValue *key = [NSValue valueWithNonretainedObject:self];
    NSMutableDictionary *dict = [gNeedsUpdateDict objectForKey:key];
    if (nil == dict) {
      QTTime duration = [self duration];
      dict = [NSMutableDictionary dictionaryWithObject:[NSValue valueWithQTTime:duration] forKey:@"duration"];
      [gNeedsUpdateDict setObject:dict forKey:key];
    }
  }
}

// call before release. remove all from assoc table.
- (void)unregisterNeedsUpdate {
  if (gNeedsUpdateDict) {
    NSValue *key = [NSValue valueWithNonretainedObject:self];
    [gNeedsUpdateDict removeObjectForKey:key];
  }
}


@end

@implementation QTMovie(AsyncLoadingPrivate)
// true if duration is not same as when read.
- (BOOL)needsUpdate {
  if (gNeedsUpdateDict) {
    NSValue *key = [NSValue valueWithNonretainedObject:self];
    NSMutableDictionary *dict = [gNeedsUpdateDict objectForKey:key];
    NSValue *value = [dict objectForKey:@"duration"];
    if (value) {
      return NSOrderedSame != QTTimeCompare([self duration], [value QTTimeValue]);
    }
  }
  return NO;
}
@end
