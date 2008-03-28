//
//  QTMovie+Async.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import "TDQTKit.h"

@interface QTMovie(AsyncLoading)

+ (QTMovie *)asyncMovieWithURL:(NSURL *)url error:(NSError **)errorp;

// with async reads, we might not be ready to read the attributes.
- (BOOL)hasAttributes;

// call before trim.
- (void)registerNeedsUpdate;

// call before release.
- (void)unregisterNeedsUpdate;

// call before save, upload
- (void)updateMovieFileIfNeeded;

@end
