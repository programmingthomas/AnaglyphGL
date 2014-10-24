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

uniform sampler2D texture0;
uniform sampler2D texture1;

varying lowp vec2 uvOut;

void main (void) {
    lowp vec4 left = texture2D(texture0, uvOut);
    lowp vec4 right = texture2D(texture1, uvOut);
    gl_FragColor = vec4(left.r, right.g, right.b, 1.0);
}