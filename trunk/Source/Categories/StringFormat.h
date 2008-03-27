//
//  StringFormat.h
//  VideoRecorder
//
//  Created by David Phillip Oster on 2/20/08.
//  Copyright 2008 Google Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSString(FormatMethods)

+ (NSString *)stringFromFileSize:(UInt64) fileSize;

+ (NSString *)stringFromTime:(NSTimeInterval) duration;

+ (NSString *)stringFromTimeShort:(NSTimeInterval) duration;
@end
