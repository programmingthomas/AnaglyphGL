// Chunk.mm
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

#include <cstdlib>

#import "Chunk.h"

const int ChunkWidth = 16;
const int ChunkLength = 16;
const int ChunkHeight = 64;

#pragma mark - Initialisation and destruction

Chunk::Chunk() {
    hasVertexData = false;
    data = (Block*)calloc(sizeof(Block), ChunkWidth * ChunkLength * ChunkHeight);
    
    //Setup some sensible defaults. The level is dirt, the remainder are air
    for (GLuint z = 0; z < ChunkHeight; z++) {
        for (GLuint y = 0; y < ChunkLength; y++) {
            for (GLuint x = 0; x < ChunkWidth; x++) {
                Set(x, y, z, z < 1 ? BlockDirt : BlockAir);
            }
        }
    }
}

Chunk::~Chunk() {
    free(data);
    if (hasVertexData) {
        DeleteVertexData();
    }
}

#pragma mark - Updating vertex data

void Chunk::UpdateVertexData(GLuint positionSlot, GLuint uvSlot) {
    //Clear all existing vertex data
    vertexData.clear();
    
    GLfloat textureOffsets[BlockCount];
    textureOffsets[BlockLeaves] = 0.75f;
    textureOffsets[BlockDirt] = 0.5f; //Or 0.375f if not the top most block
    textureOffsets[BlockStone] = 0.25f;
    textureOffsets[BlockCloud] = 0.125f;
    textureOffsets[BlockBrick] = 0;
    textureOffsets[BlockWood] = 0.62f;
    
    for (GLuint z = 0; z < ChunkHeight; z++) {
        for (GLuint y = 0; y < ChunkLength; y++) {
            for (GLuint x = 0; x < ChunkWidth; x++) {
                Block block = Get(x, y, z);
                
                if (block != BlockAir) {
                    GLfloat xOffset = textureOffsets[block];
                    //Bottom
                    AddFace(x, y, z,            1, 0, 0,    0, 1, 0,    xOffset, 0.5f);
                    //Right side
                    AddFace(x + 1, y, z + 1,        0, 1, 0,    0, 0, -1,    xOffset, 0.25f);
                    //Top
                    AddFace(x + 1, y, z + 1,    -1, 0, 0,   0, 1, 0,    xOffset, 0);
                    //Left side
                    AddFace(x, y, z + 1,        0, 1, 0,   0, 0, -1,    xOffset, 0.25f);
                    //Back
                    AddFace(x, y + 1, z + 1,        1, 0, 0,    0, 0, -1,   xOffset, 0.25f);
                    //Front
                    AddFace(x, y, z + 1,        1, 0, 0,    0, 0, -1,    xOffset, 0.25f);
                }
            }
        }
    }
    
    //Ensure that vertexData takes no more memory than it needs
    vertexData.shrink_to_fit();
    UpdateGLBuffers(positionSlot, uvSlot);
}

void Chunk::UpdateGLBuffers(GLuint positionSlot, GLuint uvSlot) {
    if (hasVertexData) {
        DeleteVertexData();
    }
    
    glGenVertexArraysOES(1, &_vertexArrayObject);
    glBindVertexArrayOES(_vertexArrayObject);
    glGenBuffers(1, &_vertexArrayBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexArrayBuffer);
    
    glBufferData(GL_ARRAY_BUFFER, vertexData, GL_STATIC_DRAW);
    
    GLuint _positionSlot = positionSlot;
    GLuint _textureSlot = uvSlot;
    
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(ChunkVertexData), (const GLvoid*)offsetof(ChunkVertexData, position));
    glEnableVertexAttribArray(_textureSlot);
    glVertexAttribPointer(_textureSlot, 2, GL_FLOAT, GL_FALSE, sizeof(ChunkVertexData), (const GLvoid*)offsetof(ChunkVertexData, uv));
    glBindVertexArrayOES(0);
    
    hasVertexData = true;
}

void Chunk::DeleteVertexData() {
    glDeleteBuffers(1, &_vertexArrayBuffer);
    glDeleteVertexArraysOES(1, &_vertexArrayObject);
    hasVertexData = false;
}

void Chunk::Draw() {
    glBindVertexArrayOES(_vertexArrayObject);
    glDrawArrays(GL_TRIANGLES, 0, vertexData.size());
}
