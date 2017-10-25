//
//  NUDictionaryCoder.m
//  Nursery
//
//  Created by P,T,A on 2013/11/17.
//
//

#import "NUDictionaryCoder.h"
#import "NUCharacter.h"
#import "NUPlayLot.h"

@implementation NUDictionaryCoder

- (id)new
{
	return [NSMutableDictionary new];
}

- (void)encode:(id)anObject withAliaser:(NUAliaser *)anAliaser
{
    [self encodeIndexedIvarsOf:anObject withAliaser:anAliaser];
}

- (void)encodeIndexedIvarsOf:(id)anObject withAliaser:(NUAliaser *)anAliaser
{
    NSDictionary *aDictionary = anObject;
	NUUInt64 aCount = [aDictionary count];
	if (aCount)
	{
		id *anObjectsAndKeys = malloc(sizeof(id) * aCount * 2);
        [aDictionary getObjects:anObjectsAndKeys andKeys:&anObjectsAndKeys[aCount]];
		[anAliaser encodeIndexedIvars:anObjectsAndKeys count:aCount * 2];
		free(anObjectsAndKeys);
	}
}

- (void)decode:(id)anObject withAliaser:(NUAliaser *)anAliaser
{
    [self decodeIndexedIvarsOf:anObject withAliaser:anAliaser];
}

- (void)decodeIndexedIvarsOf:(id)anObject withAliaser:(NUAliaser *)anAliaser
{
    NSMutableDictionary *aDictionary = anObject;
	[aDictionary setDictionary:[self decodeObjectWithAliaser:anAliaser]];
}

- (id)decodeObjectWithAliaser:(NUAliaser *)anAliaser
{
    NUUInt64 aSize = [anAliaser indexedIvarsSize];
	NSDictionary *aDictionary = nil;
	
	if (aSize)
	{
		NUUInt64 aCount = aSize / sizeof(NUUInt64) / 2;
		id *anObjectsAndKeys = malloc(sizeof(id) * aCount * 2);
		
		[anAliaser decodeIndexedIvar:anObjectsAndKeys count:aCount * 2 really:YES];
		
		aDictionary = [[NSDictionary alloc] initWithObjects:anObjectsAndKeys forKeys:&anObjectsAndKeys[aCount] count:aCount];
        
		free(anObjectsAndKeys);
	}
	else
		aDictionary = [NSDictionary new];
    
	return [aDictionary autorelease];
}

@end