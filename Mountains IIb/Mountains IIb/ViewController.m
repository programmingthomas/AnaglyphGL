// ViewController.m
//
// Copyright 2014 Thomas Denney
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "ViewController.h"
#import "StereoViewDelegate.h"
#import "Game.h"
#import "GameRenderer.h"

BOOL const Stereoscopic3D = YES;

@interface ViewController ()

@property StereoViewDelegate * stereoViewDelegate;
@property EAGLContext * context;
@property Game * game;
@property GameRenderer * leftEye;
@property GameRenderer * rightEye;

@end

@implementation ViewController

- (void)dealloc {
    //Allows subclasses to do proper clean up
    [EAGLContext setCurrentContext:self.context];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.context];
    
    GLKView * glkView = (GLKView*)self.view;
    glkView.context = self.context;
    glkView.drawableDepthFormat = GLKViewDrawableDepthFormat16;
    
    self.game = [Game new];
    
    GLsizei width = CGRectGetWidth(glkView.frame) * glkView.contentScaleFactor;
    GLsizei height = CGRectGetHeight(glkView.frame) * glkView.contentScaleFactor;
    
    self.stereoViewDelegate = [[StereoViewDelegate alloc] initWithContext:self.context width:width height:height];

    self.leftEye = [[GameRenderer alloc] initWithGame:self.game eye:CameraEyeLeft];
    self.rightEye = [[GameRenderer alloc] initWithGame:self.game eye:CameraEyeRight];
    
    self.stereoViewDelegate.leftEyeRenderer = self.leftEye;
    self.stereoViewDelegate.rightEyeRenderer = self.rightEye;
    
    if (Stereoscopic3D) {
        glkView.delegate = self.stereoViewDelegate;
    }
    
    self.preferredFramesPerSecond = 60;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)update {
    GLfloat ratio = CGRectGetWidth(self.view.frame) / CGRectGetHeight(self.view.frame);
    self.game.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65), ratio, 0.01f, 100.0f);
    self.game.modelMatrix = GLKMatrix4Translate(GLKMatrix4MakeRotation((float)fmod(CFAbsoluteTimeGetCurrent(), 2.0 * M_PI), 0, 0, 1), 0, 0, -10 + 5 * (float)cos(CFAbsoluteTimeGetCurrent()));
    self.game.viewMatrix = GLKMatrix4Identity;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.game drawWithCameraOffsetMatrix:GLKMatrix4Identity];
}

@end
