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

@implementation GLView

#pragma mark - UIView init

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.antiAliasEnabled = false;
        self.paused = true;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.antiAliasEnabled = false;
        self.paused = true;
        [self setupGL];
        [self startGL];
    }
    return self;
}

#pragma mark - Layer class

+(Class)layerClass
{
    return [CAEAGLLayer class];
}

#pragma mark - Setup OpenGL

-(void)setupGL
{
    [self setupLayer];
    [self setupContext];
    if (!self.antiAliasEnabled) [self setupDepthbuffer:CGSizeMake(self.frame.size.width * self.layer.contentsScale, self.frame.size.height * self.layer.contentsScale)];
    [self setupRenderbuffer];
    [self setupFramebuffer];
    if (self.antiAliasEnabled) [self setupMSAAbuffers];
    [self setupPrograms];
    self.timeOfLastUpdate = (double)CFAbsoluteTimeGetCurrent();
    //NSLog(@"Setting up at %f %f", self.bounds.size.width, self.bounds.size.height);
}

-(void)setupLayer
{
    _eaglLayer = (CAEAGLLayer*)self.layer;
    _eaglLayer.opaque = YES;
    _eaglLayer.contentsScale = self.antiAliasEnabled ? 1 : [[UIScreen mainScreen] scale] * 1;
    //_eaglLayer.contentsScale = 1;
}

- (void)setupContext {
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context) {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context]) {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

- (void)setupDepthbuffer:(CGSize)size {
    glGenRenderbuffers(1, &_depthBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER_OES, _depthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16, size.width, size.height);
    //NSLog(@"Setup depth %d at %f %f", _depthBuffer, size.width, size.height);
}

- (void)setupRenderbuffer {
    glGenRenderbuffers(1, &_renderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER_OES, _renderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:_eaglLayer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
}

- (void)setupFramebuffer {
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER_OES, _frameBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _renderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthBuffer);
    
}

-(void)setupMSAAbuffers
{
    //Generate MSAA frame and render buffers
    glGenFramebuffersOES(1, &msaaFramebuffer);
    glGenRenderbuffersOES(1, &msaaRenderbuffer);
    
    //Bind MSAA buffers
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaRenderbuffer);
    
    //Generate the depth buffer
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_RGBA8_OES, backingWidth, backingHeight);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, msaaRenderbuffer);
    glGenRenderbuffersOES(1, &msaaDepthbuffer);
    
    //Bind the msaa depth buffer
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, msaaDepthbuffer);
    glRenderbufferStorageMultisampleAPPLE(GL_RENDERBUFFER_OES, 4, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, msaaDepthbuffer);
    
}

-(void)setupPrograms
{
    NSLog(@"REMINDER: Implement setup programs");
}

#pragma mark - Game loop

-(void)startGL
{
    if (self.paused)
    {
        //glViewport(0, 0, backingWidth, backingHeight);
        if (self.displayLink == nil) self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateAndRenderAndPushToDisplay:)];
        else NSLog(@"Didn't need to setup display link");
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        self.paused = false;
        
        [self update];
        [self render];
    }
}

-(void)stopGL
{
    [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    self.paused = true;
}

-(BOOL)update
{
    //NSLog(@"REMINDER: Implement custom update function %f fps", 1.0f / self.timeSinceLastUpdate);
    return NO;
}

-(void)render
{
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_BLEND);
    glEnable(GL_DEPTH_TEST);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glClearColor(1.0, 1.0, 1.0, 1.0);
}

-(void)updateAndRenderAndPushToDisplay:(id)sender
{
    double time = (double)CFAbsoluteTimeGetCurrent();
    if (!self.paused)
    {
        if ([self update])
        {
            [EAGLContext setCurrentContext:_context];
            if (self.antiAliasEnabled)
                glBindFramebufferOES(GL_FRAMEBUFFER_OES, msaaRenderbuffer);
            
            glViewport(0, 0, backingWidth, backingHeight);
            
            self.renderWidth = backingWidth;
            self.renderHeight = backingHeight;
            
            [self render];
            
            if (self.antiAliasEnabled)
            {
                GLenum attachments[] = {GL_DEPTH_ATTACHMENT_OES};
                glDiscardFramebufferEXT(GL_READ_FRAMEBUFFER_APPLE, 1, attachments);
                
                glBindFramebufferOES(GL_READ_FRAMEBUFFER_APPLE, msaaFramebuffer);
                glBindFramebufferOES(GL_DRAW_FRAMEBUFFER_APPLE, _frameBuffer);
                
                glResolveMultisampleFramebufferAPPLE();
                
                glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderBuffer);
            }
            
            [_context presentRenderbuffer:GL_RENDERBUFFER_OES];
        }
    }
    self.timeOfLastUpdate = time;
}

#pragma mark - Generic Helper Functions

-(float)timeSinceLastUpdate
{
    return (float)MAX(0, (double)CFAbsoluteTimeGetCurrent() - self.timeOfLastUpdate);
}

+ (GLuint)setupTexture:(NSString *)fileName {
    UIImage *image = [UIImage imageNamed:fileName];
    
    CGImageRef spriteImage = image.CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    return [self setupTextureFromImage:spriteImage];
}

+ (GLuint)setupTextureFromImage:(CGImageRef)spriteImage {
    GLsizei width = (GLsizei)CGImageGetWidth(spriteImage);
    GLsizei height = (GLsizei)CGImageGetHeight(spriteImage);
    GLubyte * spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4,
                                                       CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

+(NSString*)stringWithFileContents:(NSString *)filename
{
    return [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:filename ofType:@"glsl"] encoding:NSUTF8StringEncoding error:nil];
}

-(UIImage*)capturedImage:(CGSize)size
{
    GLint bWidth = size.width, bHeight = size.height;
    
    self.renderWidth = bWidth;
    self.renderHeight = bHeight;
    
    [self createOffScreenBufferWithSize:CGSizeMake(bWidth, bHeight)];
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, _renderBuffer);
    //glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16, size.width, size.height);
    //[self setupDepthbuffer:size];
    glViewport(0, 0, size.width, size.height);
    [self render];
    
    GLuint x = 0, y = 0, width = bWidth, height = bHeight;
    GLuint dataLength = width * height * 4;
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, CGColorSpaceCreateDeviceRGB(), kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast, ref, NULL, true, kCGRenderingIntentDefault);
    NSInteger widthInPoints, heightInPoints;
    CGFloat scale = self.contentScaleFactor;
    widthInPoints = width / scale;
    heightInPoints = height / scale;
    //NSLog(@"Scale = %f, W = %f, h = %f", scale, (float)widthInPoints, (float)heightInPoints);
    UIGraphicsBeginImageContext(size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), iref);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    free(data);
    CFRelease(ref);
    CGImageRelease(iref);
    [self setupDepthbuffer:CGSizeMake(self.frame.size.width * self.layer.contentsScale, self.frame.size.height * self.layer.contentsScale)];
    [self setupFramebuffer];
    return image;
}

-(int)createOffScreenBufferWithSize:(CGSize)size
{
    [self setupDepthbuffer:size];
    GLuint textureBuffer, canvasTexture;
    glGenFramebuffersOES(1, &textureBuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, textureBuffer);
    glGenTextures(1, &canvasTexture);
    glBindTexture(GL_TEXTURE_2D, canvasTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)size.width, (int)size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, canvasTexture, 0);
    GLenum status = glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES);
    if (status != GL_FRAMEBUFFER_COMPLETE_OES)
        NSLog(@"Failed to make complete frame buffer %x", status);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, textureBuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER_OES, _depthBuffer);
    return canvasTexture;
}



@end
