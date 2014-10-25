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
        self.cameraOffset = GLKMatrix4MakeTranslation(0.05 * (eye == CameraEyeLeft ? -1 : 1), 0, 0);
    }
    return self;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self.game drawWithCameraOffsetMatrix:self.cameraOffset];
}

@end
