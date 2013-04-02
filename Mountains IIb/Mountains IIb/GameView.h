/*
 Copyright 2013 Programming Thomas
 
 Licensed under the Apache license, Version 2.0 (the License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


#import "GLView.h"
#import <GLKit/GLKit.h>

const int WORLD_WIDTH = 128;
const int WORLD_LENGTH = 128;
const int WORLD_HEIGHT = 16;

const int RENDER_DISTANCE = 32;

const float VISIBLE_ANGLE = M_PI / 3;

enum
{
    BUFFER_VERTEX_WORLD,
    BUFFER_INDEX_WORLD,
    BUFFER_VERTEX_SIMPLE,
    BUFFER_INDEX_SIMPLE,
    NUM_BUFFERS
};

enum
{
    BLOCK_AIR,
    BLOCK_LEAVES,
    BLOCK_DIRT,
    BLOCK_STONE,
    BLOCK_CLOUD,
    BLOCK_BRICK,
    BLOCK_WOOD
};

@interface GameView : GLView
{
    GLuint _buffers[NUM_BUFFERS];
    GLuint _texture;
    
    float _cameraX, _cameraY, _cameraZ;
    float _cameraXR, _cameraYR;
    
    
    GLubyte _world[WORLD_WIDTH][WORLD_LENGTH][WORLD_HEIGHT];
    
    GLuint _numberOfVertices;
    
    GLKMatrix4 _projectionMatrix;
    GLKMatrix4 _modelMatrix;
    GLKMatrix4 _viewMatrix;
    
    GLuint offscreenTextureLeft, offscreenTextureRight;
    GLuint offscreenFrameBufferLeft, offscreenFrameBufferRight;
}

@property float stereoFactor;
@property BOOL updatePosition;

@property GLProgram * stereoProgram;
@property GLProgram * mainProgram;

@end
