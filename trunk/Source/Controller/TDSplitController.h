//
//  TDSplitController.h
//  Vidnik
//
//  Created by David Phillip Oster on 3/6/08.
//  Copyright 2008 Google Inc. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>

// owned by document controls graphics of splitView.
@interface TDSplitController : NSObject {
 @private
  IBOutlet  NSSplitView   *mSplitView;
  IBOutlet  NSView        *mTableView;
  IBOutlet  NSView        *mDetailView;
  IBOutlet  id            mDelegate;
  float mLeftMinWidth;
  float mRightMinWidth;
}

@end
