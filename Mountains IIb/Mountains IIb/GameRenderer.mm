//
//  GameRenderer.m
//  Mountains IIb
//
//  Created by Thomas Denney on 25/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

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
