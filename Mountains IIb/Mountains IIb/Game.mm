//
//  Game.m
//  Mountains IIb
//
//  Created by Thomas Denney on 25/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import "Game.h"

@implementation Game

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)drawWithCameraOffsetMatrix:(GLKMatrix4)cameraOffsetMatrix {
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

@end
