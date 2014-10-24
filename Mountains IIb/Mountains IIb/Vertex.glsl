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

attribute vec4 position;

uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

attribute vec2 uv;
varying vec2 uvOut;

void main()
{
    gl_Position = projectionMatrix * modelViewMatrix * position;
    
    uvOut = uv;
}
