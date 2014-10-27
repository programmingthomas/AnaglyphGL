// Chunk.h
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

#import <GLKit/GLKit.h>
#import <OpenGLES/ES2/glext.h>

#include <vector>

#include "GLUtilities.h"

extern const int ChunkWidth;
extern const int ChunkLength;
extern const int ChunkHeight;

#define XYZ(x, y, z) z * ChunkWidth * ChunkLength + y * ChunkWidth + x

typedef struct {
    GLKVector3 position;
    GLKVector2 uv;
    GLKVector3 normal;
} ChunkVertexData;

typedef NS_ENUM(GLubyte, Block) {
    //Translucent blocks
    BlockAir,
    BlockLeaves,
    //Opaque blocks
    BlockDirt,
    BlockStone,
    BlockCloud,
    BlockBrick,
    BlockWood,
    //Number of blocks
    BlockCount
};

inline bool BlockIsTransparent(Block block) {
    return block <= BlockLeaves;
}

inline GLKVector3 NormalForTriangle(GLKVector3 p1, GLKVector3 p2, GLKVector3 p3) {
    GLKVector3 u = GLKVector3Subtract(p2, p1);
    GLKVector3 v = GLKVector3Subtract(p3, p1);
    return {u.y * v.z - u.z * v.y, u.z * v.x - u.x * v.z, u.x * v.y - u.y * v.x};
}

class Chunk {
    GLuint _vertexArrayBuffer;
    GLuint _vertexArrayObject;
    
    BOOL hasVertexData;
    
    void UpdateGLBuffers(GLuint positionSlot, GLuint uvSlot, GLuint normalSlot);
    
public:
    //I'm not sure if the inline funcitons work if this isn't public
    std::vector<ChunkVertexData> vertexData;
    
    GLKVector3 positon;
    
    Chunk();
    ~Chunk();
    
    Block * data;
    
    void UpdateVertexData(GLuint positionSlot, GLuint uvSlot, GLuint normalSlot);
    void DeleteVertexData();
    void Draw();
    
    bool visible;
    
    inline void Set(GLuint x, GLuint y, GLuint z, Block block) {
        data[XYZ(x,y,z)] = block;
    }
    
    inline Block Get(GLuint x, GLuint y, GLuint z) {
        return data[XYZ(x,y,z)];
    }
    
    //The first vector provided should be the position of the top left
    //The second vector provided should be the vector to get from the top left to the top right
    //The third vector provided should be the fector to get from the top left to the bottom left
    //These vectors are added to form the coordinates of the bottom left
    inline void AddFace(GLfloat aX, GLfloat aY, GLfloat aZ, GLfloat bX, GLfloat bY, GLfloat bZ, GLfloat cX, GLfloat cY, GLfloat cZ, GLfloat uvX, GLfloat uvY, GLKVector3 normal) {
        
        ChunkVertexData topLeft = {{aX, aY, aZ}, {uvX, uvY}};
        ChunkVertexData topRight = {{aX + bX, aY + bY, aZ + bZ}, {uvX + 0.125f, uvY}};
        ChunkVertexData bottomLeft = {{aX + cX, aY + cY, aZ + cZ}, {uvX, uvY + 0.125f}};
        ChunkVertexData bottomRight = {{aX + bX + cX, aY + bY + cY, aZ + bZ + cZ}, {uvX + 0.125f, uvY + 0.125f}};
        
        topLeft.position = GLKVector3Add(topLeft.position, positon);
        topRight.position = GLKVector3Add(topRight.position, positon);
        bottomLeft.position = GLKVector3Add(bottomLeft.position, positon);
        bottomRight.position = GLKVector3Add(bottomRight.position, positon);
        
//        GLKVector3 normal = NormalForTriangle(topLeft.position, topRight.position, bottomLeft.position);
        
        topLeft.normal = normal;
        topRight.normal = normal;
        bottomLeft.normal = normal;
        bottomRight.normal = normal;
        
        //First triangle
        vertexData.push_back(topLeft);
        vertexData.push_back(topRight);
        vertexData.push_back(bottomLeft);
        //Second triangle
        vertexData.push_back(topRight);
        vertexData.push_back(bottomLeft);
        vertexData.push_back(bottomRight);
    }
};