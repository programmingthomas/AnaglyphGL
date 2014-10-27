// StereoViewDelegate.h
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

#import <GLKit/GLKit.h>
#import "COBGLProgram.h"

@interface StereoViewDelegate : NSObject<GLKViewDelegate>

@property (nonatomic, readonly, weak) EAGLContext * context;
@property (nonatomic, readonly) GLsizei width;
@property (nonatomic, readonly) GLsizei height;

@property (nonatomic) id<GLKViewDelegate> leftEyeRenderer;
@property (nonatomic) id<GLKViewDelegate> rightEyeRenderer;

- (instancetype)initWithContext:(EAGLContext*)context width:(GLsizei)width height:(GLsizei)height;

@end
