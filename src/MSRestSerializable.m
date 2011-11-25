//
//  NSApiBase.m
//  MySugr
//
//  Created by brad phelan on 10/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "MSRestSerializable.h"
#import <RestKit/RestKit.h>
#import <objc/runtime.h>

static RKObjectSerializer * serializerFor(NSObject * serializable)
{
    RKObjectMapping * mapper = [[RKObjectManager sharedManager].mappingProvider 
        serializationMappingForClass:serializable.class];

    return [RKObjectSerializer 
        serializerWithObject:serializable 
                     mapping:mapper];
}

NSDictionary * convertToDictionary(NSObject * serializable)
{
    NSError * error;
    return [serializerFor(serializable) 
        serializedObject:&error];
}


NSString * convertToJSON(NSObject * serializable)
{
    NSError * error;
    return (NSString *)[serializerFor(serializable) 
        serializedObjectForMIMEType:RKMIMETypeJSON error:&error];
}

NSString * convertToFormURLEncoded(NSObject * serializable)
{
    NSError * error;
    return (NSString *)[serializerFor(serializable) 
        serializedObjectForMIMEType:RKMIMETypeFormURLEncoded error: &error];
}


