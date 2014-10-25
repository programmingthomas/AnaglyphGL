//
//  Game.h
//  Mountains IIb
//
//  Created by Thomas Denney on 24/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface Game : NSObject<GLKViewDelegate>

@property (nonatomic, readonly, weak) EAGLContext * context;
@property (nonatomic, readonly) GLsizei width;
@property (nonatomic, readonly) GLsizei height;

- (instancetype)initWithContext:(EAGLContext*)context width:(GLsizei)width height:(GLsizei)height;

@end
