//
//  Transcoding.h
//  Vidnik
//
//  Created by David Oster on 5/19/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TDQTKit.h"
#import "TDModelMovie.h"

BOOL NeedsTranscoding(QTMovie *inMovie);

BOOL StartsWithIFrame(QTMovie *inMovie);

@interface TDModelMovie(Transcoding)

- (BOOL)rewriteToStartWithIFrameReturningError:(NSError **)errp;

@end
