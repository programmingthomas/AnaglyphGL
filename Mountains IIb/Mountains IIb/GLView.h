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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#include <OpenGLES/EAGL.h>
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>
#import "GLProgram.h"

/*typedef struct
{
    float Position[4];
    float Normal[3];
    float TexCoord[2];
} Vertex;*/

typedef struct
{
    float Position[4];
    float TexCoord[2];
} Vertex;

@interface GLView : UIView
{
    CAEAGLLayer *_eaglLayer;
    EAGLContext *_context;
    
    GLuint _frameBuffer;
    GLuint _renderBuffer;
    GLuint _depthBuffer;
    
    GLint backingWidth, backingHeight;
    
    GLuint msaaFramebuffer, msaaRenderbuffer, msaaDepthbuffer;
}

@property CADisplayLink * displayLink;

@property BOOL antiAliasEnabled;
@property BOOL paused;
@property double timeOfLastUpdate;

+(Class)layerClass;
+(GLuint)setupTexture:(NSString *)fileName;
+ (GLuint)setupTextureFromImage:(CGImageRef)spriteImage;
+(NSString*)stringWithFileContents:(NSString*)filename;

-(void)setupGL;

-(void)setupPrograms;
-(void)setupLayer;
-(void)setupContext;
-(void)setupRenderbuffer;
-(void)setupFramebuffer;
-(void)setupDepthbuffer:(CGSize)size;
-(void)setupMSAAbuffers;

-(BOOL)update;
-(void)render;
-(void)updateAndRenderAndPushToDisplay:(id)sender;

-(void)startGL;
-(void)stopGL;

-(float)timeSinceLastUpdate;

@property float renderWidth;
@property float renderHeight;

-(UIImage*)capturedImage:(CGSize)size;
-(int)createOffScreenBufferWithSize:(CGSize)size;

@end
