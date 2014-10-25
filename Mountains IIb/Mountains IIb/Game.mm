//
//  Game.m
//  Mountains IIb
//
//  Created by Thomas Denney on 24/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import "Game.h"
#import "OffscreenBuffer.h"

@interface Game () {
    OffscreenBuffer * _left, * _right;
}

@end

@implementation Game

#pragma mark - Deallocation

- (void)dealloc {
    [EAGLContext setCurrentContext:self.context];
    [self _deleteBuffers];
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - Initialization

- (instancetype)initWithContext:(EAGLContext *)context width:(GLsizei)width height:(GLsizei)height {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
        _context = context;
        [self _configureBuffers];
    }
    return self;
}

#pragma mark - Offscreen buffer configuration

- (void)_configureBuffers {
    _left = new OffscreenBuffer(self.width, self.height);
    _right = new OffscreenBuffer(self.width, self.height);
}

- (void)_deleteBuffers {
    delete _left;
    delete _right;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor((GLfloat)ABS(sin(CFAbsoluteTimeGetCurrent())), 1, 0, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

@end
