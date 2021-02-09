//
//  NUCEndifLine.h
//  Nursery
//
//  Created by TAKATA Akifumi on 2021/02/01.
//  Copyright © 2021年 Nursery-Framework. All rights reserved.
//

#import "NUCPreprocessingDirective.h"

@class NUCDecomposedPreprocessingToken, NUCNewline;

@interface NUCEndifLine : NUCPreprocessingDirective
{
    NUCDecomposedPreprocessingToken *hash;
    NUCDecomposedPreprocessingToken *endif;
    NUCNewline *newline;
}

+ (instancetype)endifLineWithHash:(NUCDecomposedPreprocessingToken *)aHash endif:(NUCDecomposedPreprocessingToken *)anEndif newline:(NUCNewline *)aNewline;

- (instancetype)initWithHash:(NUCDecomposedPreprocessingToken *)aHash endif:(NUCDecomposedPreprocessingToken *)anEndif newline:(NUCNewline *)aNewline;

- (NUCDecomposedPreprocessingToken *)hash;
- (NUCDecomposedPreprocessingToken *)endif;
- (NUCNewline *)newline;

@end

