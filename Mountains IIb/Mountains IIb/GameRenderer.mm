// GameRenderer.mm
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

#import "GameRenderer.h"

@implementation GameRenderer

- (instancetype)initWithGame:(Game *)game eye:(CameraEye)eye {
    self = [super init];
    if (self) {
        _game = game;
        self.eye = eye;
        self.cameraOffset = 0.05;
    }
    return self;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.game drawWithCameraOffsetMatrix:self.cameraOffsetMatrix];
}

- (void)setEye:(CameraEye)eye {
    _eye = eye;
    [self _updateCameraOffsetMatrix];
}

- (void)setCameraOffset:(GLfloat)cameraOffset {
    _cameraOffset = cameraOffset;
    [self _updateCameraOffsetMatrix];
}

- (void)_updateCameraOffsetMatrix {
    _cameraOffsetMatrix = GLKMatrix4MakeTranslation(self.cameraOffset * (self.eye == CameraEyeLeft ? -1 : 1), 0, 0);
}

@end
