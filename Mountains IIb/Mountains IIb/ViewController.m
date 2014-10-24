/*
 Copyright 2013 Programming Thomas
 
 Licensed under the Apache license, Version 2.0 (the License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "ViewController.h"
#import "Game.h"

@interface ViewController ()

@property Game * game;
@property EAGLContext * context;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    self.game = [[Game alloc] initWithContext:self.context];
    
    GLKView * glkView = (GLKView*)self.view;
    glkView.context = self.context;
    
    self.preferredFramesPerSecond = 60;
}

@end
