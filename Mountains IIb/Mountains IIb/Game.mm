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
#import <vector>
//For Vertex Arrays
#import <OpenGLES/ES2/glext.h>

#import "Game.h"
#import "Chunk.h"

const int WorldWidthInChunks = 4;
const int WorldLengthInChunks = 4;

#pragma mark - Regular shader

NSString * const vertexShaderSource = @""
"attribute vec4 position;"

"uniform mat4 projectionMatrix;"
"uniform mat3 normalMatrix;"
"uniform mat4 modelViewMatrix;"
"varying float fogFactor;"
"uniform vec3 cameraPos;"
"attribute vec3 normal;"

"attribute vec2 uv;"
"varying vec2 uvOut;"
"varying float brightness;"

"void main() {"
"    vec4 vVertex = modelViewMatrix * position;"
"    gl_Position = projectionMatrix * vVertex;"
"    uvOut = uv;"
"    float distance = length(cameraPos.xy - position.xy) * 0.03;"
"    fogFactor = pow(clamp(0.0, 1.0, distance), 5.0);"
"    vec3 eyeNormal = normalize(normal);"
"    vec3 lightPosition = vec3(1.0, 1.0, 0.0);"
//Clamp to make sure that cubes don't get too dark
"    brightness = clamp(dot(eyeNormal, normalize(lightPosition)), 0.6, 1.0);"
//"    brightness = 1.0;"
"}";

NSString * const fragmentShaderSource = @""
"varying lowp vec2 uvOut;"
"uniform sampler2D texture0;"
"uniform lowp vec4 sky;"
"varying lowp float fogFactor;"
"varying lowp float brightness;"

"void main() {"
"    gl_FragColor = mix(texture2D(texture0, uvOut), sky, fogFactor);"
"    gl_FragColor.rgb *= brightness;"
"}";


@interface Game () {
    std::vector<Chunk*> _chunks;
    dispatch_queue_t queue;
}

@end

@implementation Game

#pragma mark - Deallocation

- (void)dealloc {
    [self _deleteTexture];
    [self _deleteChunks];
}

#pragma mark - Initialisation

- (instancetype)init {
    self = [super init];
    if (self) {
        [self _compileProgram];
        [self _loadTexture];
        [self _loadChunks];
        
        queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    }
    return self;
}

#pragma mark - Program creation

- (void)_compileProgram {
    _program = [[COBGLProgram alloc] initWithVertexShader:vertexShaderSource fragmentShader:fragmentShaderSource attributes:@[@"position", @"uv", @"normal"]];
}

#pragma mark - Texture management

- (void)_loadTexture {
    NSError * error;
    NSString * path = [[NSBundle mainBundle] pathForResource:@"bigtexture" ofType:@"png"];
    _texture = [GLKTextureLoader textureWithContentsOfFile:path options:@{GLKTextureLoaderGenerateMipmaps: @YES} error:&error].name;
    if (error) {
        NSLog(@"Error %@ for %@", error, path);
    }
}

- (void)_deleteTexture {
    glDeleteTextures(1, &_texture);
}

#pragma mark - Vertex data management

- (void)_loadChunks {
    for (GLuint x = 0; x < WorldWidthInChunks; x++) {
        for (GLuint y = 0; y < WorldLengthInChunks; y++) {
            Chunk * chunk = new Chunk();
            chunk->positon = GLKVector3Make(x * ChunkWidth, y * ChunkLength, 0);
            chunk->UpdateVertexData(self.program.position, self.program.uv, self.program.normal);
            _chunks.push_back(chunk);
        }
    }
}

- (void)_deleteChunks {
    for (auto chunk : _chunks) {
        delete chunk;
    }
}

#pragma mark - Updating

- (void)recalculateCameraPosition {
    GLfloat cameraX = MAX(MIN(self.cameraPosition.x, (GLfloat)WorldWidthInChunks * (GLfloat)ChunkWidth), 0.0);
    GLfloat cameraY = MAX(MIN(self.cameraPosition.y, (GLfloat)WorldLengthInChunks * (GLfloat)ChunkLength), 0.0);
    
    GLuint chunkX = (GLuint)MAX(0, MIN(floorf(cameraX / (GLfloat)ChunkWidth), WorldWidthInChunks));
    GLuint chunkY = (GLuint)MAX(0, MIN(floorf(cameraY / (GLfloat)ChunkLength), WorldLengthInChunks));
    
    
    
    GLuint chunkBlockX = MAX(0, MIN(ChunkWidth - 1, floorf(cameraX) - chunkX * ChunkWidth));
    GLuint chunkBlockY = MAX(0, MIN(ChunkLength - 1, floorf(cameraY) - chunkY * ChunkLength));
    
    GLuint chunkIndex = chunkX * WorldWidthInChunks + chunkY;
    
    auto chunk = _chunks[chunkIndex];
    if (chunk != NULL) {
        for (GLuint z = 0; z < ChunkHeight; z++) {
            if (chunk->Get(chunkBlockX, chunkBlockY, z) == BlockAir) {
                self.cameraPosition = GLKVector3Make(cameraX, cameraY, z + 2);
                break;
            }
        }
    }
    
    GLKMatrix4 cameraMatrix = GLKMatrix4Identity;
    cameraMatrix = GLKMatrix4RotateX(cameraMatrix, self.cameraRotation.x);
    cameraMatrix = GLKMatrix4RotateY(cameraMatrix, self.cameraRotation.z);
    cameraMatrix = GLKMatrix4RotateZ(cameraMatrix, self.cameraRotation.y);
    cameraMatrix = GLKMatrix4TranslateWithVector3(cameraMatrix, GLKVector3Negate(self.cameraPosition));
    
    self.viewMatrix = cameraMatrix;
    dispatch_apply(_chunks.size(), queue, ^(size_t n) {
        Chunk * chunk = _chunks[n];
        GLKVector3 difference = GLKVector3Subtract(self.cameraPosition, chunk->positon);
        GLfloat distance = GLKVector3Length(difference);
        chunk->visible = distance < 32;
    });
}

#pragma mark - Rendering

- (void)drawWithCameraOffsetMatrix:(GLKMatrix4)cameraOffsetMatrix {
    glClearColor(0.75, 0.9, 0.95, 1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    GLKMatrix4 viewMatrix = GLKMatrix4Multiply(self.viewMatrix, cameraOffsetMatrix);
    viewMatrix = GLKMatrix4Multiply(viewMatrix, self.modelMatrix);
    
    [self.program use];
    glUniform4f([self.program uniform:@"sky"], 0.75, 0.9, 0.95, 1);
    glUniform3fv([self.program uniform:@"cameraPos"], 1, self.cameraPosition.v);
    
    glUniformMatrix3fv(self.program.normalMatrix, 1, GL_FALSE, GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(viewMatrix), NULL).m);
    
    glUniformMatrix4fv(self.program.projectionMatrix, 1, GL_FALSE, self.projectionMatrix.m);
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glUniform1i(self.program.texture0, 0);

    glUniformMatrix4fv(self.program.modelViewMatrix, 1, GL_FALSE, viewMatrix.m);
    
    for (auto chunk : _chunks) {
        chunk->Draw();
    }
}

@end
