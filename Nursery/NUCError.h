//
//  NUCError.h
//  Nursery
//
//  Created by TAKATA Akifumi on 2022/03/28.
//  Copyright © 2022 Nursery-Framework. All rights reserved.
//

#import "NUCControlLine.h"

@class NUCPpTokens;

@interface NUCError : NUCControlLine
{
    NUCPpTokens *ppTokens;
}

+ (instancetype)errorWithHash:(NUCDecomposedPreprocessingToken *)aHash directiveName:(NUCDecomposedPreprocessingToken *)aDirectiveName ppTokens:(NUCPpTokens *)aPpTokens newline:(NUCNewline *)aNewline;

- (instancetype)initWithHash:(NUCDecomposedPreprocessingToken *)aHash directiveName:(NUCDecomposedPreprocessingToken *)aDirectiveName ppTokens:(NUCPpTokens *)aPpTokens newline:(NUCNewline *)aNewline;

- (NUCPpTokens *)ppTokens;

@end
