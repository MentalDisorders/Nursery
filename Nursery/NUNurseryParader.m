//
//  NUNurseryParader.m
//  Nursery
//
//  Created by Akifumi Takata on 2013/01/12.
//
//

#include <stdlib.h>
#import <Foundation/NSException.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSSet.h>

#import "NUNurseryParader.h"
#import "NUTypes.h"
#import "NUMainBranchNursery.h"
#import "NUMainBranchNursery+Project.h"
#import "NUPages.h"
#import "NUObjectTable.h"
#import "NUReversedObjectTable.h"
#import "NUSpaces.h"
#import "NURegion.h"
#import "NUOpaqueBPlusTreeNode.h"
#import "NUMainBranchAliaser.h"
#import "NUBellBall.h"
#import "NUGarden.h"
#import "NUGarden+Project.h"
#import "NUPage.h"
#import "NULocationTree.h"
#import "NULengthTree.h"

const NUUInt64 NUParaderNextLocationOffset = 69;

NSString *NUParaderInvalidNodeLocationException = @"NUParaderInvalidNodeLocationException";

@implementation NUNurseryParader

+ (id)paraderWithGarden:(NUGarden *)aGarden
{
    return [[[self alloc] initWithGarden:aGarden] autorelease];
}

- (id)initWithGarden:(NUGarden *)aGarden
{
    if (self = [super initWithGarden:aGarden])
    {
        garden = [aGarden retain];
    }
    
    return self;
}

- (void)dealloc
{
    [garden release];
    
    [super dealloc];
}

- (NUMainBranchNursery *)nursery
{
    return (NUMainBranchNursery *)[[self garden] nursery];
}

- (NUUInt64)grade
{
    return grade;
}

- (void)setGrade:(NUUInt64)aGrade
{
//    #ifdef DEBUG
    NSLog(@"%@ currentGrade:%@, aNewGrade:%@", self, @(grade), @(aGrade));
//    #endif
    
    grade = aGrade;
}

- (void)save
{
    [[self nursery] lock];
    
    [[[self nursery] pages] writeUInt64:nextLocation at:NUParaderNextLocationOffset];
    
    [[self nursery] unlock];
}

- (void)load
{
    [[self nursery] lock];
    
    nextLocation = [[[self nursery] pages] readUInt64At:NUParaderNextLocationOffset];
    [self setIsLoaded:YES];
    
    [[self nursery] unlock];
}

- (BOOL)processOneUnit
{
    BOOL aProcessed = YES;

    @try
    {
        [[self garden] lock];
        [[self nursery] lock];
 
        if ([self grade] != [[self nursery] gradeForParader])
        {
            [self setGrade:[[self nursery] gradeForParader]];
            [[self garden] moveUpTo:[self grade]];
            nextLocation = 0;
        }
        
        NURegion aFreeRegion = [[[self nursery] spaces] freeSpaceBeginningAtLocationGreaterThanOrEqual:nextLocation];
        
        if (aFreeRegion.location != NUNotFound64)
        {
            [self paradeObjectOrNodeNextTo:aFreeRegion];
        }
        else if (nextLocation)
        {
            nextLocation = 0;
            //                NSLog(@"%@:didFinishParade", self);
            [[[self nursery] spaces] minimizeSpaceIfPossible];
            [[self nursery] paraderDidFinishParade:self];
        }
    }
    @finally
    {
        [[self nursery] unlock];
        [[self garden] unlock];
    }
    
    return aProcessed;
}

- (void)paradeObjectOrNodeNextTo:(NURegion)aFreeRegion
{
    nextLocation = NUMaxLocation(aFreeRegion);

    if (nextLocation < [[[self nursery] pages] nextPageLocation])
    {
        NUBellBall aBellBall = [[[self nursery] reversedObjectTable] bellBallForObjectLocation:nextLocation];
        
        if (!NUBellBallEquals(aBellBall, NUNotFoundBellBall))
        {
            [self paradeObjectWithBellBall:aBellBall at:nextLocation nextTo:aFreeRegion];
        }
        else
        {
            NUUInt64 aNodeSize = [[[self nursery] pages] pageSize];
            
            if (nextLocation % aNodeSize == 0)
            {
                [self paradeNodeAt:nextLocation nextTo:aFreeRegion];

                NURegion aScannedRegion = [[[[self nursery] spaces] locationTree] scanSpaceContainningLocation:29106];
                if (aScannedRegion.location != NUNotFound64)
                    [self class];
            }
            else
            {
                [[NSException exceptionWithName:NSInternalInconsistencyException reason:nil userInfo:nil] raise];
            }
        }
    }
}

- (void)paradeObjectWithBellBall:(NUBellBall)aBellBall at:(NUUInt64)anObjectLocation nextTo:(NURegion)aFreeRegion
{
    NUUInt64 anObjectSize = [(NUMainBranchAliaser *)[[self garden] aliaser] sizeOfObjectForBellBall:aBellBall];
    NURegion anObjectRegion = NUMakeRegion(anObjectLocation, anObjectSize);
    NURegion aNewObjectRegion = NUMakeRegion(NUNotFound64, anObjectSize);

    [[[self nursery] spaces] releaseSpace:anObjectRegion];
    aNewObjectRegion.location = [[[self nursery] spaces] allocateSpace:anObjectSize aligned:NO preventsNodeRelease:NO];

    if (aNewObjectRegion.location == NUNotFound64 || !aNewObjectRegion.location)
        @throw [NSException exceptionWithName:NSGenericException reason:nil userInfo:nil];

    [[[self nursery] pages] copyBytesAt:anObjectRegion.location length:anObjectRegion.length to:aNewObjectRegion.location];
    [[[self nursery] objectTable] setObjectLocation:aNewObjectRegion.location for:aBellBall];
    
    [[[self nursery] reversedObjectTable] removeBellBallForObjectLocation:anObjectLocation];
    [[[self nursery] reversedObjectTable] setBellBall:aBellBall forObjectLocation:aNewObjectRegion.location];
    
    nextLocation = NUMaxLocation(anObjectRegion);
}

- (void)paradeNodeAt:(NUUInt64)aNodeLocation nextTo:(NURegion)aFreeRegion
{
    NUUInt64 aNodeSize = [[[self nursery] pages] pageSize];

    if ([[[self nursery] spaces] nodePageIsNotToBeReleased:aNodeLocation])
    {
        NURegion aNodeRegion = NUMakeRegion(aNodeLocation, aNodeSize);

        [[[self nursery] spaces] releaseSpace:aNodeRegion];
        NUUInt64 aNewNodeLocation = [[[self nursery] spaces] allocateNodePageLocation];

        if (aNodeLocation != aNewNodeLocation)
        {
            NUOpaqueBPlusTreeNode *aNode = [[[self nursery] spaces] nodeFor:aNodeLocation];

            if (aNode)
            {
                [aNode changeNodePageWith:aNewNodeLocation];
                [[[self nursery] pages] copyBytesAt:aNodeLocation length:aNodeSize to:aNewNodeLocation];
            }
            else
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:nil userInfo:nil];
        }
    }

    nextLocation = NUMaxLocation(aFreeRegion);
}

@end
