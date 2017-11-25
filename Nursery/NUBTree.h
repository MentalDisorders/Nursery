//
//  NUBTree.h
//  Nursery
//
//  Created by Akifumi Takata on 2013/01/20.
//
//

#import "NUTypes.h"
#import "NUComparator.h"
#import "NUCoding.h"

@class NUBTreeNode, NUBTreeLeaf;

@interface NUBTree : NSObject
{
    NUBTreeNode *root;
    NUUInt64 count;
    NUUInt64 depth;
    NUUInt64 keyCapacity;
    id <NUComparator> comparator;
    NUBell *bell;
}

+ (id)treeWithKeyCapacity:(NUUInt64)aKeyCapacity comparator:(id <NUComparator>)aComparator;

- (id)initWithKeyCapacity:(NUUInt64)aKeyCapacity comparator:(id <NUComparator>)aComparator;

- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id)aKey;
- (void)removeObjectForKey:(id)aKey;

- (id)firstKey;
- (id)lastKey;

- (id)keyGreaterThanOrEqualTo:(id)aKey;
- (id)keyGreaterThan:(id)aKey;
- (id)keyLessThanOrEqualTo:(id)aKey;
- (id)keyLessThan:(id)aKey;

- (NUUInt64)count;
- (NUUInt64)depth;

- (NUBTreeNode *)root;
- (NUUInt64)keyCapacity;
- (NUUInt64)minKeyCount;

- (id <NUComparator>)comparator;

- (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id aKey, id anObj, BOOL *aStop))aBlock;
- (void)enumerateKeysAndObjectsWithOptions:(NSEnumerationOptions)anOpts usingBlock:(void (^)(id aKey, id anObj, BOOL *aStop))aBlock;
- (void)enumerateKeysAndObjectsWithKeyGreaterThan:(id)aKey orEqual:(BOOL)anOrEqualFlag options:(NSEnumerationOptions)anOpts usingBlock:(void (^)(id, id, BOOL *))aBlock;
- (void)enumerateKeysAndObjectsWithKeyLessThan:(id)aKey orEqual:(BOOL)anOrEqualFlag options:(NSEnumerationOptions)anOpts usingBlock:(void (^)(id, id, BOOL *))aBlock;
- (void)enumerateKeysAndObjectsWithKeyGreaterThan:(id)aKey1 orEqual:(BOOL)anOrEqualFlag1 andKeyLessThan:(id)aKey2 orEqual:(BOOL)anOrEqualFlag2 options:(NSEnumerationOptions)anOpts usingBlock:(void (^)(id, id, BOOL *))aBlock;

+ (NUUInt64)defaultKeyCapacity;
+ (Class)defaultComparatorClass;

@end

@interface NUBTree (Coding) <NUCoding>
@end

@interface NUBTree (Private)

- (void)setRoot:(NUBTreeNode *)aRoot;
- (void)setComparator:(id <NUComparator>)aComparator;
- (void)updateKey:(id)aKey;

- (NUBTreeLeaf *)firstLeaf;
- (NUBTreeLeaf *)lastLeaf;

- (NUBTreeLeaf *)leafNodeContainingKeyGreaterThanOrEqualTo:(id)aKey keyIndex:(NUUInt64 *)aKeyIndex;
- (NUBTreeLeaf *)leafNodeContainingKeyGreaterThan:(id)aKey keyIndex:(NUUInt64 *)aKeyIndex;
- (NUBTreeLeaf *)leafNodeContainingKeyLessThanOrEqualTo:(id)aKey keyIndex:(NUUInt64 *)aKeyIndex;
- (NUBTreeLeaf *)leafNodeContainingKeyLessThan:(id)aKey keyIndex:(NUUInt64 *)aKeyIndex;

- (NUBTreeLeaf *)getNextKeyIndex:(NUUInt64 *)aKeyIndex node:(NUBTreeLeaf *)aNode;
- (NUBTreeLeaf *)getPreviousKeyIndex:(NUUInt64 *)aKeyIndex node:(NUBTreeLeaf *)aNode;

@end
