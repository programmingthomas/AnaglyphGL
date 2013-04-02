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

uniform sampler2D TextureLeft;
uniform sampler2D TextureRight;

varying lowp vec2 TexCoordOut;
void main (void)
{
    //The commented lines are an earlier version that I was working on
    //gl_FragColor = ConstantColor;
    //lowp vec4 left = texture2D(TextureLeft, TexCoordOut) * mat4(0.399, 0.687, 0.214, 0, 0,0.25,0,0, 0,0,0,0, 0,0,0,0.5);
    //lowp vec4 right = texture2D(TextureRight, TexCoordOut) * mat4(0,0,0,0, 0,0.25,0,0, 0.399, 0.687, 0.214,0, 0,0,0,0.5);
    //lowp vec4 left = texture2D(TextureLeft, TexCoordOut) + vec4(1.0,0,0,0);
    //lowp vec4 right = texture2D(TextureRight, TexCoordOut) + vec4(0,0,1.0,0);
    //gl_FragColor = vec4(left.r, 0, right.b, 1.0);
    lowp vec4 left = texture2D(TextureLeft, TexCoordOut);
    lowp vec4 right = texture2D(TextureRight, TexCoordOut);
    gl_FragColor = vec4(left.r, right.g, right.b, 1.0);
}