//
//  Game.m
//  Mountains IIb
//
//  Created by Thomas Denney on 25/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import <iostream>

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
    0.5,    0.5,    0,      0.125,  0.33
};

GLushort cubeIndexData[] = {0, 1, 2, 1, 2, 3};

@interface Game () {
    GLuint _cubeVertexBuffer;
    GLuint _cubeVertexArray, _cubeIndexArray;
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
    glGenBuffers(1, &_cubeVertexArray);
    glGenBuffers(1, &_cubeIndexArray);
    
    glBindBuffer(GL_ARRAY_BUFFER, _cubeVertexArray);
    glBufferData(GL_ARRAY_BUFFER, sizeof(cubeVertexData), cubeVertexData, GL_STATIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _cubeIndexArray);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(cubeIndexData), cubeIndexData, GL_STATIC_DRAW);
}

- (void)_deleteVertexData {
    glDeleteBuffers(1, &_cubeVertexArray);
    glDeleteBuffers(1, &_cubeIndexArray);
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
    glUniform1i(self.program.texture0, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _cubeVertexArray);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _cubeIndexArray);
    
    GLuint _positionSlot = self.program.position;
    GLuint _textureSlot = self.program.uv;
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(0));
    glEnableVertexAttribArray(_textureSlot);
    glVertexAttribPointer(_textureSlot, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat) * 5, (const GLvoid*)(sizeof(GLfloat) * 3));
    
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, 0);
}

@end
