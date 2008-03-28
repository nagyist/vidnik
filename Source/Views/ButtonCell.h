//
//  ButtonCell.h
//  Progress
//
//  Created by David Phillip Oster on 3/13/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

// I couldn't get NSButtonCell's trackMouse:... to work, so this
// replaces that method with one that works for me.
@interface ButtonCell : NSButtonCell {

}

@end
