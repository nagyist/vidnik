//
//  MoviePerformer.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/24/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

@protocol MoviePerformer
- (IBAction)play:(id)sender;

- (IBAction)pause:(id)sender;

- (IBAction)record:(id)sender;

- (IBAction)selectAll:(id)sender;

- (IBAction)selectNone:(id)sender;

- (void)setSelectionStart:(NSTimeInterval)startSecs end:(NSTimeInterval)endSecs;

- (IBAction)stop:(id)sender;

- (void)step:(int)count;

- (void)trim:(id)sender;

- (BOOL)validateMenuItem:(NSMenuItem *)anItem;

@end

