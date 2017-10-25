//
//  NUNSDate.m
//  Nursery
//
//  Created by P,T,A on 2013/11/17.
//
//

#import "NUNSDate.h"
#import "NUNSObject.h"
#import "NUCharacter.h"
#import "NUPlayLot.h"
#import "NUDateCoder.h"

@implementation NSDate (NUCharacter)

+ (BOOL)automaticallyEstablishCharacter
{
	return [self isEqual:[NSDate class]] || [self isEqual:[NUNSDate class]];
}

- (Class)classForNursery
{
    return [NUNSDate class];
}

@end

@implementation NUNSDate

+ (void)defineCharacter:(NUCharacter *)aCharacter on:(NUPlayLot *)aPlayLot
{
    [aCharacter setIsMutable:NO];
    [aCharacter addDoubleIvarWithName:@"timeIntervalSinceReferenceDate"];    
	[aCharacter setCoderClass:[NUDateCoder class]];
}

@end
