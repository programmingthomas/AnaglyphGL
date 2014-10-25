// Game.mm
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

#import <iostream>
//For Vertex Arrays
#import <OpenGLES/ES2/glext.h>

#import "Game.h"

#pragma mark - Regular shader

NSString * const vertexShaderSource = @""
"attribute vec4 position;"

"uniform mat4 projectionMatrix;"
"uniform mat4 modelViewMatrix;"

"attribute vec2 uv;"
"varying vec2 uvOut;"

"void main() {"
"    gl_Position = projectionMatrix * modelViewMatrix * position;"
"    uvOut = uv;"
"}";

NSString * const fragmentShaderSource = @""
"varying lowp vec2 uvOut;"
"uniform sampler2D texture0;"

"void main() {"
"    gl_FragColor = texture2D(texture0, uvOut);"
"}";

#pragma mark - Cube object

GLfloat cubeVertexData[] = {
    // Data layout for each line below is:
    // positionX, positionY, positionZ,     uvX, uvY
    -0.5,   -0.5,   0,      0,      0,
    0.5,    -0.5,   0,      0.125,  0,
    -0.5,   0.5,    0,      0,      0.33,
    
    0.5,    -0.5,   0,      0.125,  0,
    -0.5,   0.5,    0,      0,      0.33,
    0.5,    0.5,    0,      0.125,  0.33
};

//GLushort cubeIndexData[] = {0, 1, 2, 1, 2, 3};

@interface Game () {
    GLuint _cubeVertexArray;
    GLuint _cubeVertexBuffer/*, _cubeIndexBuffer*/;
}

@end

@implementation Game

#pragma mark - Deallocation

- (void)dealloc {
    [self _deleteTexture];
    [self _deleteVertexData];
}

#pragma mark - Initialisation

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _compileProgram];
        [self _loadTexture];
        [self _loadVertexData];
    }
    return self;
}

#pragma mark - Program creation

- (void)_compileProgram {
    _program = [[COBGLProgram alloc] initWithVertexShader:vertexShaderSource fragmentShader:fragmentShaderSource attributes:@[@"position", @"uv"]];
}

#pragma mark - Texture management

- (void)_loadTexture {
    _texture = [GLKTextureLoader textureWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"bigtexture" ofType:@"png"] options:nil error:nil].name;
}

- (void)_deleteTexture {
    glDeleteTextures(1, &_texture);
}

#pragma mark - Vertex data management

- (void)_loadVertexData {
    glGenVertexArraysOES(1, &_cubeVertexArray);
    glGenBuffers(1, &_cubeVertexBuffer);
//    glGenBuffers(1, &_cubeIndexBuffer);
    
    glBindVertexArrayOES(_cubeVertexArray);
    
    glBindBuffer(GL_ARRAY_BUFFER, _cubeVertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertexData), cubeVertexData, GL_STATIC_DRAW);
    
    GLuint _positionSlot = self.program.position;
    GLuint _textureSlot = self.program.uv;
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(0));
    glEnableVertexAttribArray(_textureSlot);
    glVertexAttribPointer(_textureSlot, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(sizeof(GLfloat) * 3));
    
    glBindVertexArrayOES(0);
}

- (void)_deleteVertexData {
    glDeleteBuffers(1, &_cubeVertexBuffer);
//    glDeleteBuffers(1, &_cubeVertexBuffer);
    glDeleteVertexArraysOES(1, &_cubeVertexArray);
}

#pragma mark - Rendering

- (void)drawWithCameraOffsetMatrix:(GLKMatrix4)cameraOffsetMatrix {
    glClearColor(1, 1, 1, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLKMatrix4 viewMatrix = GLKMatrix4Multiply(self.viewMatrix, cameraOffsetMatrix);
    GLKMatrix4 modelViewMatrix = GLKMatrix4Multiply(viewMatrix, self.modelMatrix);
    
    [self.program use];
    
    glUniformMatrix4fv(self.program.modelViewMatrix, 1, GL_FALSE, modelViewMatrix.m);
    glUniformMatrix4fv(self.program.projectionMatrix, 1, GL_FALSE, self.projectionMatrix.m);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glUniform1i(self.program.texture0, 0);
    
    glBindVertexArrayOES(_cubeVertexArray);
    glDrawArrays(GL_TRIANGLES, 0, 6);
}

@end
