//
//  NUCControlLine.h
//  Nursery
//
//  Created by TAKATA Akifumi on 2021/02/07.
//  Copyright © 2021年 Nursery-Framework. All rights reserved.
//

#import "NUCPreprocessingDirective.h"


@interface NUCControlLine : NUCPreprocessingDirective
{
    NUCPreprocessingToken *hash;
    NUCPreprocessingToken *directiveName;
}
@end

