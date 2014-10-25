//
//  Game.h
//  Mountains IIb
//
//  Created by Thomas Denney on 25/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "COBGLProgram.h"

@interface Game : NSObject {
    GLuint _texture;
}

@property (readonly) COBGLProgram * program;

@property GLKMatrix4 projectionMatrix;
@property GLKMatrix4 viewMatrix;
@property GLKMatrix4 modelMatrix;

- (void)drawWithCameraOffsetMatrix:(GLKMatrix4)cameraOffsetMatrix;

@end
