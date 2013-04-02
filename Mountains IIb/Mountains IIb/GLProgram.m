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

#import "GLProgram.h"

@implementation GLProgram

-(id)init
{
    self = [super init];
    if (self)
    {
        self.attributeNames = [NSMutableArray new];
        self.uniformNames = [NSMutableArray new];
        self.attributes = [NSMutableDictionary new];
        self.uniforms = [NSMutableDictionary new];
    }
    return self;
}

-(void)compile
{
    GLuint vertexShaderAddress = [self compileShader:self.vertexShader withType:GL_VERTEX_SHADER];
    GLuint fragmentShaderAddress = [self compileShader:self.fragmentShader withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShaderAddress);
    glAttachShader(programHandle, fragmentShaderAddress);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    for (NSString *uniformName in self.uniformNames)
    {
        GLuint uniformLocation = glGetUniformLocation(programHandle, uniformName.UTF8String);
        NSNumber *numberValue = [NSNumber numberWithInt:uniformLocation];
        [self.uniforms setObject:numberValue forKey:uniformName];
    }
    
    for (NSString *attributeName in self.attributeNames)
    {
        GLuint attributeLocation = glGetAttribLocation(programHandle, attributeName.UTF8String);
        NSNumber *numberValue = [NSNumber numberWithInt:attributeLocation];
        [self.attributes setObject:numberValue forKey:attributeName];
    }
    
    if (vertexShaderAddress) {
        glDetachShader(programHandle, vertexShaderAddress);
        glDeleteShader(vertexShaderAddress);
    }
    if (fragmentShaderAddress) {
        glDetachShader(programHandle, fragmentShaderAddress);
        glDeleteShader(fragmentShaderAddress);
    }
    
    self.programHandle = programHandle;
}

-(GLuint)addressofAttribute:(NSString *)address
{
    NSNumber *numberValue = self.attributes[address];
    return  numberValue.integerValue;
}

-(GLuint)addressOfUniform:(NSString *)uniform
{
    NSNumber *numberValue = self.uniforms[uniform];
    return  numberValue.integerValue;
}

- (GLuint)compileShader:(NSString*)shaderString withType:(GLenum)shaderType {
    
    if (!shaderString) {
        NSLog(@"Error loading shader");
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char * shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    return shaderHandle;
    
}

@end
