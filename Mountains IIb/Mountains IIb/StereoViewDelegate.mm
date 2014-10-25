//
//  Game.m
//  Mountains IIb
//
//  Created by Thomas Denney on 24/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import "StereoViewDelegate.h"
#import "OffscreenBuffer.h"

#pragma mark - Stereoscopic shader

NSString * const stereoscopicVertexShaderSource = @""
"attribute lowp vec2 uv;"
"attribute vec4 position;"

"varying vec2 uvOut;"

"void main(void) {"
"    gl_Position = position;"
"    uvOut = uv;"
"}";

NSString * const stereoscopicFragmentShaderSource = @""
"uniform sampler2D texture0;"
"uniform sampler2D texture1;"

"varying lowp vec2 uvOut;"

"void main (void) {"
"    lowp vec4 left = texture2D(texture0, uvOut);"
"    lowp vec4 right = texture2D(texture1, uvOut);"
"    gl_FragColor = vec4(left.r, right.g, right.b, 1.0);"
"}";

#pragma mark - Stereoscopic render data

GLfloat rectangleVertexData[] = {
    //VertexX, VertexY, VertexZ, uvX, uvY
    -1, 1,  0,   0, 1,
    1,  1,  0,   1, 1,
    -1,-1,  0,   0, 0,
    1, -1,  0,   1, 0
};

GLushort rectangleIndexData[] = {0, 1, 2, 1, 2, 3};

@interface StereoViewDelegate () {
    OffscreenBuffer * _leftBuffer, * _rightBuffer;
    
    GLuint _rectangleArrayBuffer, _rectangleElementBuffer;
}

@property COBGLProgram * stereoscopicProgram;

@end

@implementation StereoViewDelegate

#pragma mark - Deallocation

- (void)dealloc {
    [EAGLContext setCurrentContext:self.context];
    [self _deleteOffscreenBuffers];
    [self _deleteStereoscopicBuffers];
    [EAGLContext setCurrentContext:nil];
}

#pragma mark - Initialization

- (instancetype)initWithContext:(EAGLContext *)context width:(GLsizei)width height:(GLsizei)height {
    self = [super init];
    if (self) {
        _width = width;
        _height = height;
        _context = context;
        
        glEnable(GL_BLEND);
        glEnable(GL_DEPTH_TEST);
        
        [self _configureOffscreenBuffers];
        [self _compileStereoscopicProgram];
        [self _createStereoscopicBuffers];
    }
    return self;
}

#pragma mark - Offscreen buffer configuration

- (void)_configureOffscreenBuffers {
    _leftBuffer = new OffscreenBuffer(self.width, self.height);
    _rightBuffer = new OffscreenBuffer(self.width, self.height);
}

- (void)_deleteOffscreenBuffers {
    delete _leftBuffer;
    delete _rightBuffer;
}

#pragma mark - Stereoscopic program management

- (void)_compileStereoscopicProgram {
    self.stereoscopicProgram = [[COBGLProgram alloc] initWithVertexShader:stereoscopicVertexShaderSource fragmentShader:stereoscopicFragmentShaderSource attributes:@[@"position", @"uv"]];
}

#pragma mark - Stereoscopic buffer management

- (void)_createStereoscopicBuffers {
    glGenBuffers(1, &_rectangleArrayBuffer);
    glGenBuffers(1, &_rectangleElementBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, _rectangleArrayBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(rectangleVertexData), rectangleVertexData, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _rectangleElementBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(rectangleIndexData), rectangleIndexData, GL_STATIC_DRAW);
}

- (void)_deleteStereoscopicBuffers {
    glDeleteBuffers(1, &_rectangleArrayBuffer);
    glDeleteBuffers(1, &_rectangleElementBuffer);
}

#pragma mark - Stereoscopic rendering

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    [self _renderOffscreenBuffersForView:view drawInRect:rect];
    [self _renderStereoscopicBuffersOnScreen:view inRect:rect];
}

- (void)_renderOffscreenBuffersForView:(GLKView*)view drawInRect:(CGRect)rect {
    _leftBuffer->Bind();
    [self.leftEyeRenderer glkView:view drawInRect:rect];
    _rightBuffer->Bind();
    [self.rightEyeRenderer glkView:view drawInRect:rect];
}

- (void)_renderStereoscopicBuffersOnScreen:(GLKView*)view inRect:(CGRect)rect {
    [view bindDrawable];
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.stereoscopicProgram use];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _leftBuffer->texture);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _rightBuffer->texture);
    
    
    glUniform1i(self.stereoscopicProgram.texture0, 0);
    glUniform1i(self.stereoscopicProgram.texture1, 1);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glBindBuffer(GL_ARRAY_BUFFER, _rectangleArrayBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _rectangleElementBuffer);
    
    GLuint _positionSlot = self.stereoscopicProgram.position;
    GLuint _textureSlot = self.stereoscopicProgram.uv;
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(0));
    glEnableVertexAttribArray(_textureSlot);
    glVertexAttribPointer(_textureSlot, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(sizeof(GLfloat) * 3));
    
    
//    glUniformMatrix4fv(self.stereoProgram.modelViewMatrix, 1, GL_FALSE, GLKMatrix4Identity.m);
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
}

@end
