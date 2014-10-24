#AnaglyphGL

![A sample image produced using AnaglyphGL](http://i.imgur.com/w5PqNDq.jpg "A sample image produced with AnaglyphGL")

This repository contains various projects that I have created that demonstrate how one can use offscreen frame buffers and OpenGL shaders to create anaglyph style 3D images.

In this repository there is an example called 'Mountains IIb' that contains a simple Minecraft like world that runs on iOS.

I have achieved around 60fps with this demo on a real device, although you may achieve lower (especially on early retina devices/iPhones).

The code is licensed under Apache 2.0 although you only really need two Shaders (Stereoscopic.glsl and RegularVertex.glsl) for the blending and about thirty lines of code for the basic rendering (which can be found in GameView.m). Please feel free to adapt the code to your own projects.

There is more information [on my blog](http://programmingthomas.wordpress.com/2013/04/01/stereoscopic-3d-on-ios/).