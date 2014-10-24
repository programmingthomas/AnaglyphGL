// COBGLProgram.m
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

#import "COBGLProgram.h"

@interface COBGLProgram () {
    //Don't access these directly (they aren't meant for public use)
    GLuint _program, _vertexShader, _fragmentShader;
}

///------------------------
///@name Private properties
///------------------------

@property NSMutableDictionary * uniforms;
@property NSMutableDictionary * attributes;

///---------------------
///@name Private methods
///---------------------

/**
 Compiles a shader to the given address
 @param shader The shader to compile into
 @param type Either GL_VERTEX_SHADER or GL_FRAGMENT_SHADER
 @param source The source for the shader
 @return YES upon success
 */
- (BOOL)compileShader:(GLuint*)shader type:(GLenum)type source:(NSString*)source;

@end

@implementation COBGLProgram

#pragma mark - Destruction

//dealloc comes first, per NYT style guide
- (void)dealloc {
    [self delete];
}

- (void)delete {
    if (_vertexShader) {
        glDeleteShader(_vertexShader);
    }
    if (_fragmentShader) {
        glDeleteShader(_fragmentShader);
    }
    if (_program) {
        glDeleteProgram(_program);
    }
    
    _program = _vertexShader = _fragmentShader = 0;
}

#pragma mark - Initialization

- (instancetype)initWithVertexShader:(NSString *)vertexShader fragmentShader:(NSString *)fragmentShader attributes:(NSArray *)attributes {
    self = [super init];
    if (self) {
        _program = glCreateProgram();
        
        BOOL compiledVertex = [self compileShader:&_vertexShader type:GL_VERTEX_SHADER source:vertexShader];
        BOOL compiledFragment = [self compileShader:&_fragmentShader type:GL_FRAGMENT_SHADER source:fragmentShader];
        
        if (!compiledFragment || !compiledVertex) {
            glDeleteProgram(_program);
            return nil;
        }
        
        glAttachShader(_program, _vertexShader);
        glAttachShader(_program, _fragmentShader);
        
        self.attributes = [NSMutableDictionary new];
        
        //Register attributes
        GLuint i = 0;
        for (NSString * attributeName in attributes) {
            glBindAttribLocation(_program, i, [attributeName UTF8String]);
            self.attributes[attributeName] = @(i);
            i++;
        }
        
        //Link the program
        GLint linkStatus;
        glLinkProgram(_program);
        //Debug
        {
            GLint logLength;
            glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &logLength);
            if (logLength > 0) {
                GLchar * log = (GLchar*)malloc(logLength);
                glGetProgramInfoLog(_program, logLength, &logLength, log);
                NSLog(@"Program link failed: %s", log);
                free(log);
            }
        }
        
        glGetProgramiv(_program, GL_LINK_STATUS, &linkStatus);
        
        if (!linkStatus) {
            [self delete];
            return nil;
        }
        
        //Register uniforms
        self.uniforms = [NSMutableDictionary new];
        GLint totalUniforms;
        glGetProgramiv(_program, GL_ACTIVE_UNIFORMS, &totalUniforms);
        for (GLint i = 0; i < totalUniforms; i++) {
            int name_len, num = 0;
            GLenum type = GL_ZERO;
            //
            char name[256];
            glGetActiveUniform(_program, i, sizeof(name) - 1, &name_len, &num, &type, name);
            name[name_len] = 0;
            GLuint location = glGetUniformLocation(_program, name);
            self.uniforms[[NSString stringWithUTF8String:name]] = @(location);
        }
        
        //Cleanup
        if (_vertexShader) {
            glDetachShader(_program, _vertexShader);
            glDeleteShader(_vertexShader);
        }
        
        if (_fragmentShader) {
            glDetachShader(_program, _fragmentShader);
            glDeleteShader(_fragmentShader);
        }
        
        //Set standard attributes/uniforms for easy access
        _position = [self.attributes[@"position"] unsignedIntValue];
        _normal = [self.attributes[@"normal"] unsignedIntValue];
        _uv = [self.attributes[@"uv"] unsignedIntValue];
        _color = [self.attributes[@"color"] unsignedIntValue];
        
        _modelViewProjectionMatrix = [self.uniforms[@"modelViewProjectionMatrix"] unsignedIntValue];
        _modelViewMatrix = [self.uniforms[@"modelViewMatrix"] unsignedIntValue];
        _projectionMatrix = [self.uniforms[@"projectionMatrix"] unsignedIntValue];
        _normalMatrix = [self.uniforms[@"normalMatrix"] unsignedIntValue];
        _texture0 = [self.uniforms[@"texture0"] unsignedIntValue];
        _texture1 = [self.uniforms[@"texture1"] unsignedIntValue];
        
        _ambientColor = [self.uniforms[@"ambientColor"] unsignedIntValue];
        _diffuseColor = [self.uniforms[@"diffuseColor"] unsignedIntValue];
        _specularColor = [self.uniforms[@"specularColor"] unsignedIntValue];
    }
    return self;
}

- (instancetype)initWithVertexShaderFile:(NSString *)vertexShaderPath fragmentShader:(NSString *)fragmentShaderPath attributes:(NSArray *)attributes {
    NSString * vertexShader = [NSString stringWithContentsOfFile:vertexShaderPath encoding:NSUTF8StringEncoding error:nil];
    NSString * fragmentShader = [NSString stringWithContentsOfFile:fragmentShaderPath encoding:NSUTF8StringEncoding error:nil];
    if (vertexShader && fragmentShader) {
        self = [self initWithVertexShader:vertexShader fragmentShader:fragmentShader attributes:attributes];
    }
    else {
        if (!vertexShader) {
            NSLog(@"Not found %@", vertexShaderPath);
        }
        if (!fragmentShader) {
            NSLog(@"Not found %@", fragmentShaderPath);
        }
    }
    return self;
}

- (instancetype)initWithBundleVertexShaderFile:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName attributes:(NSArray *)attributes {
    NSString * vertexShaderPath = [[NSBundle mainBundle] pathForResource:vertexShaderName ofType:nil];
    NSString * fragmentShaderPath = [[NSBundle mainBundle] pathForResource:fragmentShaderName ofType:nil];
    return [self initWithVertexShaderFile:vertexShaderPath fragmentShader:fragmentShaderPath attributes:attributes];
}

#pragma mark - Shader compilation

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)source {
    GLint status;
    
    const GLchar * cSource;
    cSource = (GLchar*)[source UTF8String];
    
    if (!cSource) {
        return NO;
    }
    
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &cSource, NULL);
    glCompileShader(*shader);
    
    //Debugging
    {
        GLint logLength;
        glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
        if (logLength > 0) {
            GLchar *log = (GLchar *)malloc(logLength);
            glGetShaderInfoLog(*shader, logLength, &logLength, log);
            NSLog(@"Shader compile log: %s", log);
            free(log);
        }
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

#pragma mark - Use

- (void)use {
        glUseProgram(_program);
}

- (GLuint)attribute:(NSString *)attribute {
    return [self.attributes[attribute] unsignedIntValue];
}

- (GLuint)uniform:(NSString *)uniform {
    return [self.uniforms[uniform] unsignedIntValue];
}

@end
