// StereoViewDelegate.mm
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

#import "StereoViewDelegate.h"
#import "OffscreenBuffer.h"
//For Vertex Arrays
#import <OpenGLES/ES2/glext.h>

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
    1,  1,  0,   1, 1,
    -1,-1,  0,   0, 0,
    1, -1,  0,   1, 0
};

@interface StereoViewDelegate () {
    OffscreenBuffer * _leftBuffer, * _rightBuffer;
    
    GLuint _rectangleArrayBuffer;
    GLuint _rectangleVertexArray;
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
        glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
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
    glGenVertexArraysOES(1, &_rectangleVertexArray);
    glBindVertexArrayOES(_rectangleVertexArray);
    glGenBuffers(1, &_rectangleArrayBuffer);
    
    glBindBuffer(GL_ARRAY_BUFFER, _rectangleArrayBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(rectangleVertexData), rectangleVertexData, GL_STATIC_DRAW);
    
    GLuint _positionSlot = self.stereoscopicProgram.position;
    GLuint _textureSlot = self.stereoscopicProgram.uv;
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(0));
    glEnableVertexAttribArray(_textureSlot);
    glVertexAttribPointer(_textureSlot, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(sizeof(GLfloat) * 3));
    glBindVertexArrayOES(0);
}

- (void)_deleteStereoscopicBuffers {
    glDeleteBuffers(1, &_rectangleArrayBuffer);
    glDeleteVertexArraysOES(1, &_rectangleVertexArray);
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
    
    glBindVertexArrayOES(_rectangleVertexArray);
    glDrawArrays(GL_TRIANGLES, 0, 6);
    
    
    
//    glUniformMatrix4fv(self.stereoProgram.modelViewMatrix, 1, GL_FALSE, GLKMatrix4Identity.m);
    
//    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
}

@end
