//
//  Game.h
//  Mountains IIb
//
//  Created by Thomas Denney on 25/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface Game : NSObject

@property GLKMatrix4 projectionMatrix;
@property GLKMatrix4 cameraMatrix;

- (void)drawWithCameraOffsetMatrix:(GLKMatrix4)cameraOffsetMatrix;

@end
