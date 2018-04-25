//
//  NUNurseryNetClient.m
//  Nursery
//
//  Created by Akifumi Takata on 2017/12/31.
//  Copyright © 2017年 Nursery-Framework. All rights reserved.
//

#import "NUNurseryNetClient.h"
#import "NUNurseryNetService.h"
#import "NUNurseryNetMessage.h"
#import "NUNurseryNetMessageArgument.h"
#import "NUBranchNursery.h"
#import "NUBellBall.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>

NSString *NUNurseryNetClientNetworkException = @"NUNurseryNetClientNetworkException";

const NUUInt64 NUNurseryNetClientReadBufferSize = 4096;
const NSTimeInterval NUNurseryNetClientRunLoopRunningTimeInterval = 0.003;
const NSTimeInterval NUNurseryNetClientSleepTimeInterval = 0.001;


@implementation NUNurseryNetClient

- (instancetype)initWithServiceName:(NSString *)aServiceName
{
    if (self = [super init])
    {
        _lock = [NSRecursiveLock new];
        _statusLock = [NSLock new];
        _statusCondition = [NSCondition new];
        _serviceName = [aServiceName copy];
    }
    
    return self;
}

- (void)dealloc
{
    [_netService release];
    _netService = nil;
    
    [_serviceBrowser release];
    _serviceBrowser = nil;
    
    [_serviceName release];
    _serviceName = nil;
    
    [_nursery release];
    _nursery = nil;
    
    [_statusCondition release];
    _statusCondition = nil;
    
    [_statusLock release];
    _statusLock = nil;
    
    [_lock release];
    _lock = nil;
    
    [super dealloc];
}

- (NUNurseryNetClientStatus)status
{
    [[self statusLock] lock];
    
    NUNurseryNetClientStatus aStatus = status;
    
    [[self statusLock] unlock];
    
    return aStatus;
}

- (void)setStatus:(NUNurseryNetClientStatus)aStatus
{
    [[self statusLock] lock];
    status = aStatus;
    [[self statusLock] unlock];
}

- (BOOL)isNotStarted
{
    return [self status] == NUNurseryNetClientStatusNotStarted;
}

- (BOOL)isFindingService
{
    return [self status] == NUNurseryNetClientStatusFindingService;
}

- (BOOL)isSendingMessage
{
    return [self status] == NUNurseryNetClientStatusSendingMessage;
}

- (BOOL)isReceivingMessage
{
    return [self status] == NUNurseryNetClientStatusReceivingMessage;
}

- (void)start
{
    [[self lock] lock];
    
    if ([self isNotStarted])
    {
        [[self statusCondition] lock];
        
        NSThread *aThread = [[[NSThread alloc] initWithBlock:^{
            [self startInNewThread];
        }] autorelease];
        [aThread setName:@"org.nursery-framework.NUNurseryNetClientNetworking"];
        [self setThread:aThread];
        
        [aThread start];
        
        while ([self isNotStarted])
            [[self statusCondition] wait];
        
        [[self statusCondition] unlock];
    }
    
    [[self lock] unlock];
}

- (void)stop
{
    [[self lock] lock];
    
    [self netClientWillStop];
    
    [[self thread] cancel];
    
    [[self statusCondition] lock];
    
    while ([self status] == NUNurseryNetClientStatusDidStop)
        [[self statusCondition] wait];
    
    [[self statusCondition] unlock];
    
    [[self lock] unlock];
}

- (void)startInNewThread
{
    [[self statusCondition] lock];
    
    [self setServiceBrowser:[[NSNetServiceBrowser new] autorelease]];
    [[self serviceBrowser] setDelegate:self];

    [self findNetService];
    [self resolveNetService];
    [self getStreams];

    [[self inputStream] open];
    [[self outputStream] open];
    
    [self setStatus:NUNurseryNetClientStatusRunning];
    
    [[self statusCondition] signal];
    [[self statusCondition] unlock];
    
    [self runUntileCancel];
    
    [[self inputStream] close];
    [[self outputStream] close];
    
    [[self statusCondition] lock];
    
    [self setStatus:NUNurseryNetClientStatusDidStop];
    
    [[self statusCondition] unlock];
}

- (void)findNetService
{
    [self setStatus:NUNurseryNetClientStatusFindingService];
    [[self serviceBrowser] searchForServicesOfType:NUNurseryNetServiceType inDomain:@""];
    
    while ([self status] != NUNurseryNetClientStatusDidFindService)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:NUNurseryNetClientRunLoopRunningTimeInterval]];
}

- (void)resolveNetService
{
    [self setStatus:NUNurseryNetClientStatusResolvingService];
    [[self netService] setDelegate:self];
    [[self netService] resolveWithTimeout:0];
    
    while ([self status] != NUNurseryNetClientStatusDidResolveService)
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:NUNurseryNetClientRunLoopRunningTimeInterval]];
}

- (void)getStreams
{
    CFHostRef aHost = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)[[self netService] hostName]);
    CFReadStreamRef aReadStream;
    CFWriteStreamRef aWriteStream;
    NSInputStream *anInputStream;
    NSOutputStream *anOutputStream;
    
    CFStreamCreatePairWithSocketToCFHost(kCFAllocatorDefault, aHost, (SInt)[[self netService] port], &aReadStream, &aWriteStream);
    CFRelease(aHost);
    
    CFReadStreamSetProperty(aReadStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(aWriteStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    anInputStream = (NSInputStream *)aReadStream;
    anOutputStream = (NSOutputStream *)aWriteStream;
    
    [self setInputStream:anInputStream];
    [self setOutputStream:anOutputStream];
    
    CFRelease(aReadStream);
    CFRelease(aWriteStream);
}

- (void)runUntileCancel
{
//    BOOL aShouldSetKeepAliveOptions = YES;
    
    while (![[self thread] isCancelled])
    {
        [NSThread sleepForTimeInterval:NUNurseryNetClientSleepTimeInterval];
        
        [[self statusCondition] lock];
        
//        if (aShouldSetKeepAliveOptions && [[self inputStream] streamStatus] == NSStreamStatusOpen)
//        {
//            [self setKeepAliveOptionsForSocket:[self nativeSocketHandleForStream:[self inputStream]]];
//            aShouldSetKeepAliveOptions = NO;
//        }

        if ([[self inputStream] streamStatus] == NSStreamStatusAtEnd)
            [self setStatus:NUNurseryNetClientStatusDidFail];

        switch ([self status])
        {
            case NUNurseryNetClientStatusSendingMessage:
                if ([[self outputStream] hasSpaceAvailable])
                    [self sendMessageOnStream];
                break;
            case NUNurseryNetClientStatusReceivingMessage:
                if ([[self inputStream] hasBytesAvailable])
                    [self receiveMessageOnStream];
                break;
            default:
                break;
        }
        
        if (!([self isSendingMessage] || [self isReceivingMessage]))
            [[self statusCondition] signal];
        
        [[self statusCondition] unlock];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aBrowser
           didFindService:(NSNetService *)aService
               moreComing:(BOOL)aMoreComing
{
    NSLog(@"browser:%@\nservice:%@", aBrowser, aService);

    NSLog(@"name:%@", [aService name]);
    NSLog(@"host name:%@", [aService hostName]);
    
    if (!aMoreComing)
    {
        [aBrowser stop];
        
        [[self serviceBrowser] setDelegate:nil];;
        [[self serviceBrowser] removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        [self setNetService:aService];
        [self setStatus:NUNurseryNetClientStatusDidFindService];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
    NSLog(@"%@", [[self netService] hostName]);
    
    [[self netService] stop];
    [[self netService] setDelegate:nil];
    
    [self setStatus:NUNurseryNetClientStatusDidResolveService];
}

- (void)sendMessage:(NUNurseryNetMessage *)aSendingMessage
{
    [[self statusCondition] lock];
    
    [aSendingMessage serialize];
    [self setSendingMessage:aSendingMessage];
    [self setStatus:NUNurseryNetClientStatusSendingMessage];
    
    [[self statusCondition] signal];
    [[self statusCondition] unlock];
    
    [[self statusCondition] lock];
    
    @try
    {
        while ([self isSendingMessage])
            [[self statusCondition] wait];
        
        if ([self status] == NUNurseryNetClientStatusDidFail)
            @throw [NSException exceptionWithName:NUNurseryNetClientNetworkException reason:nil userInfo:nil];
    }
    @finally
    {
        [[self statusCondition] unlock];
    }
}

- (void)messageDidSend
{
    [self setStatus:NUNurseryNetClientStatusDidSendMessage];
}

- (void)receiveMessage
{
    [[self statusCondition] lock];
    
    [self setStatus:NUNurseryNetClientStatusReceivingMessage];
    
    [[self statusCondition] signal];
    [[self statusCondition] unlock];
    
    [[self statusCondition] lock];
    
    @try
    {
        while ([self isReceivingMessage])
            [[self statusCondition] wait];
        
        if ([self status] == NUNurseryNetClientStatusDidFail)
            @throw [NSException exceptionWithName:NUNurseryNetClientNetworkException reason:nil userInfo:nil];
    }
    @finally
    {
        [[self statusCondition] unlock];
    }
}

- (void)messageDidReceive
{
    [self setStatus:NUNurseryNetClientStatusDidReceiveMessage];
}

- (void)sendAndReceiveMessage:(NUNurseryNetMessage *)aSendingMessage
{
    [self sendMessage:aSendingMessage];
    [self receiveMessage];
}

@end

@implementation NUNurseryNetClient (MessagingToNetService)

- (NUUInt64)openGarden
{
    NUUInt64 aPairID = 0;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindOpenGarden];
        
        [self sendAndReceiveMessage:aMessage];
        
        aPairID = [[[self receivedMessage] argumentAt:0] UInt64FromValue];
    }
    @finally
    {
        [[self lock] unlock];
    }
    
    return aPairID;
}

- (void)closeGardenWithID:(NUUInt64)anID
{
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindCloseGarden];
        
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        
        [self sendMessage:aMessage];
    }
    @finally
    {
        [[self lock] unlock];
    }
}

- (NUUInt64)rootOOPForGardenWithID:(NUUInt64)anID
{
    NUUInt64 aRootOOP = 0;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindRootOOP];
        
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        
        [self sendAndReceiveMessage:aMessage];
        
        aRootOOP = [[[self receivedMessage] argumentAt:0] UInt64FromValue];
    }
    @finally
    {
        [[self lock] unlock];

    }

    return aRootOOP;
}

- (NUUInt64)latestGrade
{
    NUUInt64 aLatestGrade = NUNilGrade;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindLatestGrade];
        
        [self sendAndReceiveMessage:aMessage];
        
        aLatestGrade = [[[self receivedMessage] argumentAt:0] UInt64FromValue];
    }
    @finally
    {
        [[self lock] unlock];

    }

    return aLatestGrade;
}

- (NUUInt64)olderRetainedGrade
{
    NUUInt64 anOlderRetainedGrade = NUNilGrade;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindOlderRetainedGrade];
        
        [self sendAndReceiveMessage:aMessage];
        
        anOlderRetainedGrade = [[[self receivedMessage] argumentAt:0] UInt64FromValue];
    }
    @finally
    {
        [[self lock] unlock];
    }

    return anOlderRetainedGrade;
}

- (NUUInt64)retainLatestGradeByGardenWithID:(NUUInt64)anID
{
    NUUInt64 aGrade = NUNilGrade;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindRetainLatestGrade];
        
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        
        [self sendAndReceiveMessage:aMessage];
        
        aGrade = [[[self receivedMessage] argumentAt:0] UInt64FromValue];
    }
    @finally
    {
        [[self lock] unlock];
    }
    
    return aGrade;
}

- (NUUInt64)retainGradeIfValid:(NUUInt64)aGrade byGardenWithID:(NUUInt64)anID
{
    NUUInt64 aRetainedGradeOrNilGrade = NUNilGrade;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindRetainGradeIfValid];
        
        [aMessage addArgumentOfTypeUInt64WithValue:aGrade];
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        
        [self sendAndReceiveMessage:aMessage];
        
        aRetainedGradeOrNilGrade = [[[self receivedMessage] argumentAt:0] UInt64FromValue];
    }
    @finally
    {
        [[self lock] unlock];

    }

    return aRetainedGradeOrNilGrade;
}

- (void)retainGrade:(NUUInt64)aGrade byGardenWithID:(NUUInt64)anID
{
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindRetainGrade];
        
        [aMessage addArgumentOfTypeUInt64WithValue:aGrade];
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        
        [self sendAndReceiveMessage:aMessage];

    }
    @finally
    {
        [[self lock] unlock];

    }
}

- (void)releaseGradeLessThan:(NUUInt64)aGrade byGardenWithID:(NUUInt64)anID
{
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindReleaseGradeLessThan];
        
        [aMessage addArgumentOfTypeUInt64WithValue:aGrade];
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        
        [self sendAndReceiveMessage:aMessage];
    }
    @finally
    {
        [[self lock] unlock];
    }
}

- (NSData *)callForPupilWithOOP:(NUUInt64)anOOP gradeLessThanOrEqualTo:(NUUInt64)aGrade gardenWithID:(NUUInt64)anID containsFellowPupils:(BOOL)aContainsFellowPupils
{
    NSData *aPupilsData = nil;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindCallForPupil];
        
        [aMessage addArgumentOfTypeUInt64WithValue:anOOP];
        [aMessage addArgumentOfTypeUInt64WithValue:aGrade];
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        [aMessage addArgumentOfTypeBOOLWithValue:aContainsFellowPupils];
        
        [self sendAndReceiveMessage:aMessage];
        
        aPupilsData = [[[self receivedMessage] argumentAt:0] dataFromValue];
    }
    @finally
    {
        [[self lock] unlock];
    }
    
    return aPupilsData;
}

- (NUFarmOutStatus)farmOutPupils:(NSData *)aPupilData rootOOP:(NUUInt64)aRootOOP gardenWithID:(NUUInt64)anID fixedOOPs:(NSData **)aFixedOOPs latestGrade:(NUUInt64 *)aLatestGrade
{
    NUFarmOutStatus aStatus = NUFarmOutStatusFailed;
    
    [[self lock] lock];
    
    @try
    {
        NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindFarmOutPupils];
        
        [aMessage addArgumentOfTypeBytesWithValue:(void *)[aPupilData bytes] length:[aPupilData length]];
        [aMessage addArgumentOfTypeUInt64WithValue:aRootOOP];
        [aMessage addArgumentOfTypeUInt64WithValue:anID];
        
        [self sendAndReceiveMessage:aMessage];
        
        aStatus = (NUFarmOutStatus)[[[self receivedMessage] argumentAt:0] UInt64FromValue];
        
        *aFixedOOPs = [[[self receivedMessage] argumentAt:1] dataFromValue];
        *aLatestGrade = [[[self receivedMessage] argumentAt:2] UInt64FromValue];
    }
    @finally
    {
        [[self lock] unlock];
    }
    
    return aStatus;
}

- (void)netClientWillStop
{
    NUNurseryNetMessage *aMessage = [NUNurseryNetMessage messageOfKind:NUNurseryNetMessageKindNetClientWillStop];
    
    [self sendMessage:aMessage];
}

@end