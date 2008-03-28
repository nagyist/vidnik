//
//  TDAppController.h
//  Vidnik
//
//  Created by David Phillip Oster on 2/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

@class TDConfiguration;

@interface TDAppController : NSObject {
  TDConfiguration *mConfig;
}

- (TDConfiguration *)config;
- (void)setConfig:(TDConfiguration *)config;

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;

@end

