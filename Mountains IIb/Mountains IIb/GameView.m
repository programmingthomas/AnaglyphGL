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

#import "GameView.h"

@implementation GameView

-(void)setupPrograms
{
    [self compileMainProgram];
    [self setupTextures];
    [self setupBuffers];
    [self stereoSetup];
    [self createWorld];
    [self viewSetup];
    
    self.stereoFactor = 0.05;
    
    NSLog(@"Hello!\nTo use this demo:\na) Pinch to change distance between the eyes\nb) Tap to stop moving\nc) Pan around with one finger");
}

-(void)compileMainProgram
{
    self.mainProgram = [[COBGLProgram alloc] initWithBundleVertexShaderFile:@"Vertex.glsl" fragmentShader:@"Fragment.glsl" attributes:@[@"position", @"uv"]];
    self.stereoProgram = [[COBGLProgram alloc] initWithBundleVertexShaderFile:@"RegularVertex.glsl" fragmentShader:@"Stereoscopic.glsl" attributes:@[@"position", @"uv"]];
}

-(void)setupTextures
{
    _texture = [GLView setupTexture:@"bigtexture.png"];
}

-(void)setupBuffers
{
    glGenBuffers(NUM_BUFFERS, _buffers);
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[BUFFER_VERTEX_WORLD]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _buffers[BUFFER_INDEX_WORLD]);
}

-(void)createWorld
{
    for (int x = 0; x < WORLD_WIDTH; x++)
    {
        for (int y = 0; y < WORLD_LENGTH; y++)
        {
            if (x % WORLD_HEIGHT == WORLD_HEIGHT - 1 || x % WORLD_HEIGHT == 1 || y % WORLD_HEIGHT == WORLD_HEIGHT - 1 || y % WORLD_HEIGHT == 1) _world[x][y][1] = BLOCK_BRICK;
            
        }
    }
    
    for (int x = 0; x < WORLD_WIDTH; x++)
    {
        for (int y = 0; y < WORLD_LENGTH; y++)
        {
            _world[x][y][0] = BLOCK_STONE;
            if (x % WORLD_HEIGHT == 0 || y % WORLD_HEIGHT == 0) _world[x][y][1] = BLOCK_DIRT;
            if (x % WORLD_HEIGHT == 0 && y % WORLD_HEIGHT == 0)
            {
                //Plant tree
                int treeTop = MIN(5, WORLD_HEIGHT - 2);
                for (int z = 2; z < treeTop; z++) _world[x][y][z] = BLOCK_WOOD;
                if (x - 1 > 0) _world[x - 1][y][treeTop] = BLOCK_LEAVES;
                if (x + 1 < WORLD_WIDTH - 1) _world[x + 1][y][treeTop] = BLOCK_LEAVES;
                if (y - 1 > 0) _world[x][y - 1][treeTop] = BLOCK_LEAVES;
                if (y + 1 < WORLD_LENGTH - 1) _world[x][y + 1][treeTop] = BLOCK_LEAVES;
                _world[x][y][treeTop + 1] = BLOCK_LEAVES;
            }
        }
    }
    
    for (int x = 0; x < WORLD_WIDTH; x++)
    {
        int height = x % (WORLD_HEIGHT * 2);
        if (height > WORLD_HEIGHT) height = 2 * WORLD_HEIGHT - height;
        for (int y = 0; y < WORLD_LENGTH; y++)
        {
            int yheight = y % (WORLD_HEIGHT * 2);
            if (yheight > WORLD_HEIGHT) yheight = 2 * WORLD_HEIGHT - yheight;
            yheight = height - yheight;
            for (int z = 1; z < yheight - 1; z++)
            {
                _world[x][y][z] = BLOCK_DIRT;
            }
        }
    }
    
    for (int x = WORLD_HEIGHT / 2; x < WORLD_WIDTH; x += WORLD_HEIGHT)
    {
        for (int y = WORLD_HEIGHT / 2; y < WORLD_LENGTH; y += WORLD_HEIGHT)
        {
            int cloudHeight = WORLD_HEIGHT - 1;
            _world[x][y][cloudHeight] = BLOCK_CLOUD;
            _world[x + 1][y][cloudHeight] = BLOCK_CLOUD;
            _world[x][y + 1][cloudHeight] = BLOCK_CLOUD;
            _world[x - 1][y][cloudHeight] = BLOCK_CLOUD;
            _world[x][y - 1][cloudHeight] = BLOCK_CLOUD;
        }
    }
    
    _cameraX = WORLD_WIDTH / 2;
    _cameraY = WORLD_LENGTH / 2;
    _cameraXR = 0;
    _cameraYR = 0;
}

-(void)viewSetup
{
    self.updatePosition = true;
    UIPanGestureRecognizer * panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [self addGestureRecognizer:panGesture];
    UIPinchGestureRecognizer * pinchGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinch:)];
    [self addGestureRecognizer:pinchGesture];
    UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self addGestureRecognizer:tapGesture];
}

-(void)stereoSetup
{
    Vertex simpleVertex[] = {
        {{-1, 1,0,0},{0,1}},
        {{1,1,0,0},{1,1}},
        {{-1, -1,0,0},{0,0}},
        {{1,-1,0,0},{1,0}}
    };
    
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[BUFFER_VERTEX_SIMPLE]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(simpleVertex), simpleVertex, GL_STATIC_DRAW);
    
    GLubyte simpleIndex[] = {0,1,2,1,2,3};
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _buffers[BUFFER_INDEX_SIMPLE]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(simpleIndex), simpleIndex, GL_STATIC_DRAW);
    
    //Offscreen texture setup
    
    float w = self.bounds.size.width * self.contentScaleFactor;
    float h = self.bounds.size.height * self.contentScaleFactor;
    
    glGenTextures(1, &offscreenTextureLeft);
    glBindTexture(GL_TEXTURE_2D, offscreenTextureLeft);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glGenFramebuffersOES(1, &offscreenFrameBufferLeft);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, offscreenFrameBufferLeft);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
    
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, offscreenTextureLeft, 0);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _frameBuffer);
    
    //Offscreen texture right
    
    glGenTextures(1, &offscreenTextureRight);
    glBindTexture(GL_TEXTURE_2D, offscreenTextureRight);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    
    glGenFramebuffersOES(1, &offscreenFrameBufferRight);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, offscreenFrameBufferRight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
    
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, offscreenTextureRight, 0);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, _frameBuffer);
}

-(BOOL)update
{
    if (self.updatePosition)
    {
        _cameraX += (sinf(_cameraXR)) * self.timeSinceLastUpdate;
        _cameraY += (cosf(_cameraXR)) * self.timeSinceLastUpdate;
    }
    _cameraX = MAX(0, MIN(WORLD_WIDTH, _cameraX));
    _cameraY = MAX(0, MIN(WORLD_LENGTH, _cameraY));
    
    if (_cameraXR > M_PI) _cameraXR -= 2 * M_PI;
    else if (_cameraXR < -M_PI) _cameraXR += 2 * M_PI;
    
    _cameraYR = MAX(-VISIBLE_ANGLE - M_PI_2, MIN(VISIBLE_ANGLE - M_PI_2, _cameraYR));
    
    int maxHeight = WORLD_HEIGHT;
    for (int z = 0; z < WORLD_HEIGHT; z++)
    {
        if (_world[(int)_cameraX][(int)_cameraY][z] == BLOCK_AIR)
        {
            maxHeight = z;
            break;
        }
    }
    _cameraZ = maxHeight + 1.5;
    
    _projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65), self.renderWidth / self.renderHeight, 0.01, -100);
    _modelMatrix = _viewMatrix = GLKMatrix4Identity;
    
    _viewMatrix = GLKMatrix4RotateX(_viewMatrix, _cameraYR);
    _viewMatrix = GLKMatrix4RotateZ(_viewMatrix, _cameraXR);
    
    _viewMatrix = GLKMatrix4Translate(_viewMatrix, -_cameraX , -_cameraY , -_cameraZ );
    
    _modelMatrix = GLKMatrix4Translate(_modelMatrix, 0, 0, -4);
    GLKMatrix4 viewModelMatrix = GLKMatrix4Multiply(_viewMatrix, _modelMatrix);

    [self.mainProgram use];
    
    glUniformMatrix4fv(self.mainProgram.projectionMatrix, 1, GL_FALSE, _projectionMatrix.m);
    glUniformMatrix4fv(self.mainProgram.modelViewMatrix, 1, GL_FALSE, viewModelMatrix.m);
    
    [self updateGeometry];
    
    return YES;
}

-(void)updateGeometry
{
    //Update based on world:
    
    float eth = 1.0f / 8.0f, thrd = 1.0f / 3.0f, t3 = 2.0f / 3.0f;
    
    Vertex standardVertex[] = {
        //Top
        {{0,0,1,0}, {0,0}},
        {{1,0,1,0}, {eth,0}},
        {{0,1,1,0}, {0,thrd}},
        {{1,1,1,0}, {eth,thrd}},
        //Front
        {{0,0,1,0}, {0,thrd}},
        {{1,0,1,0}, {eth,thrd}},
        {{0,0,0,0}, {0,t3}},
        {{1,0,0,0}, {eth,t3}},
        //Back
        {{0,1,1,0}, {0,thrd}},
        {{1,1,1,0}, {eth,thrd}},
        {{0,1,0,0}, {0,t3}},
        {{1,1,0,0}, {eth,t3}},
        //Bottom
        {{0,0,0,0}, {0,t3}},
        {{1,0,0,0}, {eth,t3}},
        {{0,1,0,0}, {0,1}},
        {{1,1,0,0}, {eth,1}},
        //Left
        {{0,0,1,0}, {0,thrd}},
        {{0,1,1,0}, {eth,thrd}},
        {{0,0,0,0}, {0,t3}},
        {{0,1,0,0}, {eth,t3}},
        //Right
        {{1,0,1,0}, {0,thrd}},
        {{1,1,1,0}, {eth,thrd}},
        {{1,0,0,0}, {0,t3}},
        {{1,1,0,0}, {eth,t3}}
    };
    
    float textureOffsets[] = {0, 0.75, 0.5, 0.25, 0.125, 0, 0.625};
    
    int insertCount = 0;
    
    int totalVertices = 0;
    
    for (int x = 0; x < WORLD_WIDTH; x++)
    {
        for (int y = 0; y < WORLD_LENGTH; y++)
        {
            float xDiff = x - _cameraX, yDiff = y - _cameraY;
            if (xDiff * xDiff + yDiff * yDiff < RENDER_DISTANCE * RENDER_DISTANCE)
            {
                if ([self columnIsVisibleFromCamera:x andY:y])
                {
                
                    for (int z = 0; z < WORLD_HEIGHT; z++)
                    {
                        if (_world[x][y][z] > BLOCK_AIR)
                        {
                            
                            {
                                if (z < WORLD_HEIGHT - 1 && _world[x][y][z + 1] <= BLOCK_LEAVES) totalVertices += 4;
                                if  (y > 0 && _world[x][y - 1][z] <= BLOCK_LEAVES) totalVertices += 4;
                                if  (y < WORLD_LENGTH - 1 && _world[x][y + 1][z] <= BLOCK_LEAVES) totalVertices += 4;
                                if (z > 0 && _world[x][y][z - 1] <= BLOCK_LEAVES) totalVertices += 4;
                                if (x > 0 && _world[x - 1][y][z] <= BLOCK_LEAVES) totalVertices += 4;
                                if (x < WORLD_WIDTH - 1 && _world[x + 1][y][z] <= BLOCK_LEAVES) totalVertices += 4;
                            }
                        }
                    }
                }
            }
        }
    }
    
    Vertex worldVertices[totalVertices];
    
    for (int x = 0; x < WORLD_WIDTH; x++)
    {
        for (int y = 0; y < WORLD_LENGTH; y++)
        {
            float xDiff = x - _cameraX, yDiff = y - _cameraY;
            if (xDiff * xDiff + yDiff * yDiff < RENDER_DISTANCE * RENDER_DISTANCE) {
                
                if ([self columnIsVisibleFromCamera:x andY:y])
                {
                    for (int z = 0; z < WORLD_HEIGHT; z++)
                    {
                        if (_world[x][y][z] > BLOCK_AIR)
                        {
                            
                                if  (z < WORLD_HEIGHT - 1 && _world[x][y][z + 1] == BLOCK_AIR)
                                {
                                    //Top face is visible
                                    /*worldVertices[insertCount] = standardVertex[0];
                                    worldVertices[insertCount + 1] = standardVertex[1];
                                    worldVertices[insertCount + 2] = standardVertex[2];
                                    worldVertices[insertCount + 3] = standardVertex[3];*/
                                    for (int n = 0; n < 4; n++)
                                    {
                                        worldVertices[insertCount + n] = standardVertex[n];
                                        worldVertices[insertCount + n].Position[0] += x;
                                        worldVertices[insertCount + n].Position[1] += y;
                                        worldVertices[insertCount + n].Position[2] += z;
                                        worldVertices[insertCount + n].TexCoord[0] += textureOffsets[_world[x][y][z]];
                                    }
                                    insertCount += 4;
                                }
                                //Front is visible
                                if (y > 0 && _world[x][y - 1][z] <= BLOCK_LEAVES)
                                {
                                    for (int n = 0; n < 4; n++)
                                    {
                                        worldVertices[insertCount + n] = standardVertex[n + 4];
                                        worldVertices[insertCount + n].Position[0] += x;
                                        worldVertices[insertCount + n].Position[1] += y;
                                        worldVertices[insertCount + n].Position[2] += z;
                                        worldVertices[insertCount + n].TexCoord[0] += textureOffsets[_world[x][y][z]];
                                    }
                                    insertCount += 4;
                                }
                                //Back is visible
                                if  (y < WORLD_LENGTH - 1 && _world[x][y + 1][z] <= BLOCK_LEAVES)
                                {
                                    for (int n = 0; n < 4; n++)
                                    {
                                        worldVertices[insertCount + n] = standardVertex[n + 8];
                                        worldVertices[insertCount + n].Position[0] += x;
                                        worldVertices[insertCount + n].Position[1] += y;
                                        worldVertices[insertCount + n].Position[2] += z;
                                        worldVertices[insertCount + n].TexCoord[0] += textureOffsets[_world[x][y][z]];
                                    }
                                    insertCount += 4;
                                }
                                //Bottom is visible
                                if (z > 0 && _world[x][y][z - 1] <= BLOCK_LEAVES)
                                {
                                    for (int n = 0; n < 4; n++)
                                    {
                                        worldVertices[insertCount + n] = standardVertex[n + 12];
                                        worldVertices[insertCount + n].Position[0] += x;
                                        worldVertices[insertCount + n].Position[1] += y;
                                        worldVertices[insertCount + n].Position[2] += z;
                                        worldVertices[insertCount + n].TexCoord[0] += textureOffsets[_world[x][y][z]];
                                    }
                                    insertCount += 4;
                                }
                                //Left is visible
                                if (x > 0 && _world[x - 1][y][z] <= BLOCK_LEAVES)
                                {
                                    for (int n = 0; n < 4; n++)
                                    {
                                        worldVertices[insertCount + n] = standardVertex[n + 16];
                                        worldVertices[insertCount + n].Position[0] += x;
                                        worldVertices[insertCount + n].Position[1] += y;
                                        worldVertices[insertCount + n].Position[2] += z;
                                        worldVertices[insertCount + n].TexCoord[0] += textureOffsets[_world[x][y][z]];
                                    }
                                    insertCount += 4;
                                }
                                //Right is visible
                                if (x < WORLD_WIDTH - 1 && _world[x + 1][y][z] <= BLOCK_LEAVES)
                                {
                                    for (int n = 0; n < 4; n++)
                                    {
                                        worldVertices[insertCount + n] = standardVertex[n + 20];
                                        worldVertices[insertCount + n].Position[0] += x;
                                        worldVertices[insertCount + n].Position[1] += y;
                                        worldVertices[insertCount + n].Position[2] += z;
                                        worldVertices[insertCount + n].TexCoord[0] += textureOffsets[_world[x][y][z]];
                                    }
                                    insertCount += 4;
                                }
                        
                        }
                    }
                }
            }
        }
    }
    
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[BUFFER_VERTEX_WORLD]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(worldVertices), worldVertices, GL_DYNAMIC_DRAW);
    
    GLuint indexData[(totalVertices / 4) * 6];
    int i = 0;
    int p = 0;
    
    for (int n = 0; n < (totalVertices / 4); n++)
    {
        indexData[i] = p;
        indexData[i + 1] = p + 1;
        indexData[i + 2] = p + 2;
        indexData[i + 3] = p + 1;
        indexData[i + 4] = p + 2;
        indexData[i + 5] = p + 3;
        i += 6;
        p += 4;
    }
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _buffers[BUFFER_INDEX_WORLD]);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indexData), indexData, GL_DYNAMIC_DRAW);
    
    _numberOfVertices = (totalVertices / 4) * 6;
    //NSLog(@"%d:%d:%f", totalVertices, _numberOfVertices, _cameraXR);
}

-(BOOL)columnIsVisibleFromCamera:(int)x andY:(int)y
{
    if (abs(_cameraX - x) < 6 && abs(_cameraY - y) < 6) return YES;
    float cameraAngle = _cameraXR;
    float angle = atan2f(x - _cameraX, y - _cameraY);
    //cameraAngle = GLKMathRadiansToDegrees(cameraAngle);
    //angle = GLKMathRadiansToDegrees(angle);
    /*float anglediff = fmodf(angle - cameraAngle + M_PI, M_PI * 2) - M_PI;
    float visibleAngle = VISIBLE_ANGLE * (1 + fabsf(_cameraXR) / 2);
    return (anglediff <= visibleAngle && anglediff >= -visibleAngle) || (anglediff <= -(M_PI * 2) + visibleAngle && anglediff >= -(M_PI*2) - visibleAngle);*/
    //float angleDiff = atan2f(sinf(angle - cameraAngle), cosf(angle - cameraAngle)) + M_PI;
    //return  ABS(MIN((2 * M_PI) - ABS(cameraAngle - angle), ABS(cameraAngle - angle))) < VISIBLE_ANGLE;
    return ABS(atan2f(sinf(cameraAngle - angle), cosf(cameraAngle - angle))) < VISIBLE_ANGLE * 1.5;
}

-(void)render
{
    if (self.stereoFactor >= 0.01)
    {
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
        glEnable(GL_BLEND);
        glEnable(GL_DEPTH_TEST);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glClearColor(0, 0, 0, 1.0);
        
        GLKMatrix4 leftMatrix = GLKMatrix4Identity;
        leftMatrix = GLKMatrix4Translate(leftMatrix, -self.stereoFactor, 0, 0);
        leftMatrix = GLKMatrix4RotateX(leftMatrix, _cameraYR);
        leftMatrix = GLKMatrix4RotateZ(leftMatrix, _cameraXR);
        
        leftMatrix = GLKMatrix4Translate(leftMatrix, -_cameraX , -_cameraY , -_cameraZ );
        
        GLKMatrix4 rightMatrix = GLKMatrix4Identity;
        rightMatrix = GLKMatrix4Translate(rightMatrix, self.stereoFactor, 0, 0);
        rightMatrix = GLKMatrix4RotateX(rightMatrix, _cameraYR);
        rightMatrix = GLKMatrix4RotateZ(rightMatrix, _cameraXR);
        
        rightMatrix = GLKMatrix4Translate(rightMatrix, -_cameraX , -_cameraY , -_cameraZ );
        
        
        [self.mainProgram use];
        
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, offscreenFrameBufferLeft);
        glUniformMatrix4fv(self.mainProgram.modelViewMatrix, 1, GL_FALSE, GLKMatrix4Multiply(leftMatrix, _modelMatrix).m);
        [self renderScene];
        
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, offscreenFrameBufferRight);
        glUniformMatrix4fv(self.mainProgram.modelViewMatrix, 1, GL_FALSE, GLKMatrix4Multiply(rightMatrix, _modelMatrix).m);
        [self renderScene];
        
        glBindFramebufferOES(GL_FRAMEBUFFER_OES, _frameBuffer);
        
        glViewport(0, 0, self.renderWidth, self.renderHeight);
        [self.stereoProgram use];
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, offscreenTextureLeft);
        glActiveTexture(GL_TEXTURE1);
        glBindTexture(GL_TEXTURE_2D, offscreenTextureRight);
        
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glUniform1i(self.stereoProgram.texture0, 0);
        glUniform1i(self.stereoProgram.texture1, 1);
        
        glBindBuffer(GL_ARRAY_BUFFER, _buffers[BUFFER_VERTEX_SIMPLE]);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _buffers[BUFFER_INDEX_SIMPLE]);
        
        GLuint _positionSlot = self.stereoProgram.position;
        GLuint _textureSlot = self.stereoProgram.uv;
        
        glEnableVertexAttribArray(_positionSlot);
        glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)offsetof(Vertex, Position));
        glEnableVertexAttribArray(_textureSlot);
        glVertexAttribPointer(_textureSlot, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)offsetof(Vertex, TexCoord));
        
        
        glUniformMatrix4fv(self.stereoProgram.modelViewMatrix, 1, GL_FALSE, GLKMatrix4Identity.m);
        glUniformMatrix4fv(self.stereoProgram.projectionMatrix, 1, GL_FALSE, GLKMatrix4Identity.m);
        
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_BYTE, 0);
    }
    else [self renderScene];
}

-(void)renderScene
{
    glViewport(0, 0, self.renderWidth, self.renderHeight);
    
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(0.75, 0.75, 0.8, 1.0);
    
    [self.mainProgram use];
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _texture);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(self.mainProgram.texture0, 0);
    
    glBindBuffer(GL_ARRAY_BUFFER, _buffers[BUFFER_VERTEX_WORLD]);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _buffers[BUFFER_INDEX_WORLD]);
    
    GLuint positionAttrib = self.mainProgram.position;
    GLuint textureAttrib = self.mainProgram.uv;
    
    glEnableVertexAttribArray(positionAttrib);
     glVertexAttribPointer(positionAttrib, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)offsetof(Vertex, Position));
    
    glEnableVertexAttribArray(textureAttrib);
    glVertexAttribPointer(textureAttrib, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid*)offsetof(Vertex, TexCoord));
    
    glDrawElements(GL_TRIANGLES, _numberOfVertices, GL_UNSIGNED_INT, 0);
}

-(void)pan:(UIPanGestureRecognizer*)panGesture
{
    CGPoint pan = [panGesture translationInView:self];
    [panGesture setTranslation:CGPointZero inView:self];
    _cameraXR += pan.x / self.renderWidth * 2;
    _cameraYR += pan.y / self.renderHeight * 2;
    //NSLog(@"Set %f %f", _cameraXR, _cameraYR);
}

-(void)pinch:(UIPinchGestureRecognizer*)pinchGesture
{
    self.stereoFactor *= pinchGesture.scale;
    [pinchGesture setScale:1];
}

-(void)tap:(UITapGestureRecognizer*)tapGesture
{
    if (tapGesture.state == UIGestureRecognizerStateEnded)
    {
        self.updatePosition = !self.updatePosition;
    }
}

@end
