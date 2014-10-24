// COBGLProgram.h
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

@import Foundation;
@import GLKit;

/**
 This class provides an easy way to compile an OpenGL shader and access its attributes and uniforms
 
 Basic usage is:
 
 * Create the shader using an appropriate method
 * Call -use
 * Get attribute/uniform locations
 * Configure values
 */
@interface COBGLProgram : NSObject

///--------------------
///@name Initialization
///--------------------

/**
 Initializes the program by compiling the source.
 @param vertexShader The source for the vertex shader
 @param fragmentShader The source for the fragment shader
 @param attributes An array of strings containing the names of the attributes (uniforms can be found automatically)
 @return The program, provided that both shaders compiled successfully
 @warning If you're writing these in code then you should probably make sure that you insert \n at the end of each line to make debugging easier
 */
- (instancetype)initWithVertexShader:(NSString*)vertexShader fragmentShader:(NSString*)fragmentShader attributes:(NSArray*)attributes;

/**
 Initializes the program by compiling the source code in the specified files
 @param vertexShaderPath The path to the vertex shader file
 @param fragmentShaderPath The path to the fragment shader file
 @param attributes An array of strings containing the names of the attributes (uniforms can be found automatically)
 @return The program
 @warning If these files don't exist or they cannot be compiled then the compile log will be logged to the console and nil will be returned
 */
- (instancetype)initWithVertexShaderFile:(NSString*)vertexShaderPath fragmentShader:(NSString*)fragmentShaderPath attributes:(NSArray*)attributes;

/**
 Initializes the program by compiling the source code in the specified bundle files
 @param vertexShaderName The name of the vertex shader resource
 @param fragmentShaderName The name of the fragment shader resource
 @param attributes An array of strings containing the names of the attributes
 @return The program
 @warning If these files don't exist or they cannot be compiled then the compile log will be logged to the console and nil will be returned
 */
- (instancetype)initWithBundleVertexShaderFile:(NSString *)vertexShaderName fragmentShader:(NSString *)fragmentShaderName attributes:(NSArray *)attributes;

///-----------------------
///@name Using the program
///-----------------------

/**
 Calls glUseProgram(_program)
 */
- (void)use;

/**
 @param attribute The name of the attribute to get the address of
 @return The address of the attribute
 @note On compilation several standard attributes are set as properties
 */
- (GLuint)attribute:(NSString*)attribute;

/**
 @param uniform The name of the uniform to get the address of
 @return The address of the uniform
 @note On compilation several standard uniforms are set as properties
 */
- (GLuint)uniform:(NSString*)uniform;

///-------------------------
///@name Standard attributes
///-------------------------

@property (readonly) GLuint position;
@property (readonly) GLuint normal;
@property (readonly) GLuint uv;
@property (readonly) GLuint color;

///-----------------------
///@name Standard uniforms
///-----------------------

@property (readonly) GLuint modelViewProjectionMatrix;
@property (readonly) GLuint modelViewMatrix;
@property (readonly) GLuint projectionMatrix;
@property (readonly) GLuint normalMatrix;
@property (readonly) GLuint texture0;
@property (readonly) GLuint texture1;
@property (readonly) GLuint ambientColor;
@property (readonly) GLuint diffuseColor;
@property (readonly) GLuint specularColor;

@end
