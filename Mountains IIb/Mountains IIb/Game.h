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

- (instancetype)initWithContext:(EAGLContext*)context;

@end
