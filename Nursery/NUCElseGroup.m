//
//  NUCElseGroup.m
//  Nursery
//
//  Created by TAKATA Akifumi on 2021/02/01.
//  Copyright © 2021年 Nursery-Framework. All rights reserved.
//

#import "NUCElseGroup.h"

@implementation NUCElseGroup

+ (instancetype)elseGroupWithHash:(NUCPreprocessingToken *)aHash directiveName:(NUCPreprocessingToken *)anElse newline:(NUCNewline *)aNewline group:(NUCGroup *)aGroup
{
    return [[[self alloc] initWithHash:aHash directiveName:anElse newline:aNewline group:aGroup] autorelease];
}

- (instancetype)initWithHash:(NUCPreprocessingToken *)aHash directiveName:(NUCPreprocessingToken *)anElse newline:(NUCNewline *)aNewline group:(NUCGroup *)aGroup
{
    if (self = [super initWithType:NUCLexicalElementElseType])
    {
        hash = [aHash retain];
        directiveName = [anElse retain];
        newline = [aNewline retain];
        group = [aGroup retain];
    }
    
    return self;
}

- (void)dealloc
{
    [hash release];
    [directiveName release];
    [newline release];
    [group release];
    
    [super dealloc];
}

- (NUCPreprocessingToken *)hash
{
    return hash;
}

- (NUCPreprocessingToken *)else
{
    return directiveName;
}

- (NUCNewline *)newline
{
    return newline;
}

- (NUCGroup *)group
{
    return group;
}

@end
