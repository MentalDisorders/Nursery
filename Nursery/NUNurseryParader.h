//
//  NUNurseryParader.h
//  Nursery
//
//  Created by Akifumi Takata on 2013/01/12.
//
//

#import "NUTypes.h"
#import "NUThreadedChildminder.h"

extern NSString *NUParaderInvalidNodeLocationException;

@class NUMainBranchNursery, NUOpaqueBPlusTreeNode;

@interface NUNurseryParader : NUThreadedChildminder
{
    NUUInt64 nextLocation;
    NUUInt64 grade;
}

+ (id)paraderWithGarden:(NUGarden *)aGarden;

- (NUUInt64)grade;
- (NUMainBranchNursery *)nursery;

- (void)save;
- (void)load;

- (void)paradeObjectOrNodeNextTo:(NURegion)aFreeRegion;
- (void)paradeObjectWithBellBall:(NUBellBall)aBellBall at:(NUUInt64)anObjectLocation nextTo:(NURegion)aFreeRegion;
- (void)paradeNodeAt:(NUUInt64)aNodeLocation nextTo:(NURegion)aFreeRegion;
- (void)computeMovedNodeRegionInto:(NURegion *)aMovedNodeRegion fromCurrentNodeRegion:(NURegion)aCurrentNodeRegion withFreeRegion:(NURegion)aFreeRegion newFreeRegion1Into:(NURegion *)aNewFreeRegion1 newFreeRegion2Into:(NURegion *)aNewFreeRegion2;
- (NUOpaqueBPlusTreeNode *)nodeFor:(NUUInt64)aNodeLocation;

@end
