//
//  VidnikMain.m
// 
//  Created by David Phillip Oster on 2/12/08.
//  Copyright Google 2008. 
// Licensed under the Apache License, Version 2.0 (the "License"); you may not
// use this file except in compliance with the License.  You may obtain a copy
// of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
// License for the specific language governing permissions and limitations under
// the License.

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
