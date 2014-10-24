//
//  Game.m
//  Mountains IIb
//
//  Created by Thomas Denney on 24/10/2014.
//  Copyright (c) 2014 Programming Thomas. All rights reserved.
//

#import "Game.h"

@implementation Game

- (instancetype)initWithContext:(EAGLContext *)context {
    self = [super init];
    if (self) {
        _context = context;
    }
    return self;
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
}

@end
