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

@implementation MSRestSerializable


- (RKObjectMapping *) _mapper
{
    RKObjectMappingProvider * provider = [RKObjectManager sharedManager].mappingProvider;
    RKObjectMapping * mapping = [provider objectMappingForClass:[self class]];
    return mapping;


}

- (RKObjectMapping *) _serializer
{
    RKObjectMappingProvider * provider = [RKObjectManager sharedManager].mappingProvider;
    RKObjectMapping * mapping = [provider serializationMappingForClass:[self class]];
    return mapping;
}



- (BOOL)isNew
{
    BOOL hasId = class_getProperty([self class], [@"id" UTF8String]) != NULL;
    return ([self valueForKey:@"id"] == NULL || !hasId);
}


- (NSDictionary *)convertToDictionary
{
    NSError * error;
    // First convert the query object into a dictionary
    RKObjectSerializer * querySerializer = [RKObjectSerializer serializerWithObject:self mapping:[self _serializer]];
    return [querySerializer serializedObject:&error];
}


- (NSString*)convertToJSON
{
    RKObjectSerializer * serializer = [RKObjectSerializer serializerWithObject:self mapping:[self _serializer]];
    NSError * error;
    NSString * text = (NSString *)[serializer serializedObjectForMIMEType:RKMIMETypeJSON error:&error];
    return text;
}

- (NSString *)convertToFormURLEncoded
{
    RKObjectSerializer * serializer = [RKObjectSerializer serializerWithObject:self mapping:[self _serializer]];

    NSError * error;
    NSString * text = (NSString *)[serializer serializedObjectForMIMEType:RKMIMETypeFormURLEncoded error: &error];
    return text;
}

- (NSString*)description
{


    RKObjectSerializer * serializer = [RKObjectSerializer serializerWithObject:self mapping:[self _serializer]];

    NSError * error;
    NSString * description = (NSString *)[serializer serializedObjectForMIMEType:RKMIMETypeJSON error: &error];
    return [description stringByReplacingOccurrencesOfString:@"\"" withString:@"'"];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[MSRestSerializable allocWithZone:zone] init];
}

@end

@implementation MSRestSerializableResource

+ (RKObjectRouter *) router
{
    return [RKObjectManager sharedManager].router;
}

+ (Class) classForResource
{
    NSAssert(NO, @"Stub implementation. Must be implemented in subclass");
    return NULL;
}


+ (void) initializeRouting
{
    RKObjectRouter * router = [self router];
    
    NSString * collectionResource = [self resourcePath];
    NSString * objectResource = [NSString stringWithFormat:@"%@/:id", collectionResource];
    
    if([self isSingleton])
    {
        objectResource = collectionResource;
    }
    
    if ([self canCreate]){
        [router routeClass:self toResourcePath:collectionResource forMethod:RKRequestMethodPOST];
    }
    
    if ([self canRead]){
        [router routeClass:self toResourcePath:objectResource forMethod:RKRequestMethodGET];
    }
    
    if ([self canUpdate])
    {
        [router routeClass:self toResourcePath:objectResource forMethod:RKRequestMethodPUT];
    }
    
    if ([self canDelete])
    {
        [router routeClass:self toResourcePath:objectResource forMethod:RKRequestMethodDELETE];
    }
    
}


+ (NSString *) resourcePath{
    NSAssert(NO, @"Not implemented");
    return NULL;
}

+ (bool) isSingleton{
    return true;
}
+ (bool) canCreate{
    return true;
}
+ (bool) canRead{
    return true;
}
+ (bool) canUpdate{
    return true;
}
+ (bool) canDelete{
    return true;
}


- (void) saveWithDelegate:(id<RKObjectLoaderDelegate>)delegate
{
    if ([self isNew])
    {
        NSAssert(self.canCreate, @"Object must allow create to be created");
        NSLog(@"Creating new object\n%@", self);
        // Save a new object
        [[RKObjectManager sharedManager] postObject:self mapResponseWith:[self _mapper] delegate:delegate];
    }else{
        NSAssert(self.canUpdate, @"Object must allow update to be updated");
        NSLog(@"Updating object\n%@", self);
        // Update the object as it allready has an id
        [[RKObjectManager sharedManager] putObject:self mapResponseWith:[self _mapper] delegate:delegate];
    }
}

- (void)deleteWithDelegate:(id<RKObjectLoaderDelegate>)delegate
{
    NSAssert(self.canDelete, @"Object must allow delete to be deleted");
    [[RKObjectManager sharedManager] deleteObject:self withDelegate:delegate];
}

// Find an instance by id
+ (void) find:(NSNumber *)id withDelegate:(id<RKObjectLoaderDelegate>)delegate
{
    MSRestSerializable * instance = [[self alloc] init];
    [instance setValue:id forKey:@"id"];
    [[RKObjectManager sharedManager] getObject:instance 
                               mapResponseWith:[instance _mapper] 
                                      delegate:delegate];
}

// Load collection
+ (void) loadCollectionWithDelegate:(id<RKObjectLoaderDelegate>)delegate
{
    RKObjectManager * objectManager = [RKObjectManager sharedManager];
    RKObjectMapping * mapping = [objectManager.mappingProvider 
                                 objectMappingForClass:self ];
    
    [objectManager loadObjectsAtResourcePath:[self resourcePath] 
                               objectMapping:mapping 
                                    delegate:delegate];
}


// Load collection with query
+ (void) loadCollectionThroughQuery:(MSRestSerializable *)mappableQueryObject 
                       withDelegate:(id<RKObjectLoaderDelegate>)delegate
{
    
    RKObjectManager * objectManager = [RKObjectManager sharedManager];
    RKObjectMapping * mapping = [objectManager.mappingProvider
                                 objectMappingForClass:self ];
    
    
    // Append the dictionary to the resource as query parameters
    NSString * resourcePath = RKPathAppendQueryParams([self resourcePath], [mappableQueryObject convertToDictionary]);
    
    // Load the objects at the query
    [objectManager loadObjectsAtResourcePath:resourcePath 
                               objectMapping:mapping 
                                    delegate:delegate];
}


@end
