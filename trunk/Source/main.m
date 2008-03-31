//
//  VidnikMain.m
// 
//  Created by David Phillip Oster on 2/12/08.
//  Copyright Google 2008. Open source under Apache license Documentation/Copying in this project
//

#import <Cocoa/Cocoa.h>
#import <Foundation/NSDebug.h>

int main(int argc, char *argv[]) {

// change 0 to 1 on next line for zombie checking n the debug build 
#if 0 && defined(DEBUG) && DEBUG
NSDebugEnabled = YES;
NSZombieEnabled = YES;
#endif
  int val = NSApplicationMain(argc,  (const char **) argv);
  return val;
}
