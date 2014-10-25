//
//  GameRenderer.h
//  Mountains IIb
//
//  Created by Thomas Denney on 25/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import "StereoViewDelegate.h"
#import "Game.h"

typedef NS_ENUM(NSUInteger, CameraEye) {
    CameraEyeLeft,
    CameraEyeRight
};

@interface GameRenderer : NSObject<GLKViewDelegate>

@property (nonatomic) CameraEye eye;
@property (nonatomic) GLfloat cameraOffset;

@property (readonly)GLKMatrix4 cameraOffsetMatrix;

@property (nonatomic, strong, readonly) Game * game;

- (instancetype)initWithGame:(Game*)game eye:(CameraEye)eye;

@end
