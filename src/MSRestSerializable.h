//
//  NSApiBase.h
//  MySugr
//
//  Created by brad phelan on 10/4/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSDate+APIDate.h"
#import <RestKit/RestKit.h>

@interface MSRestSerializable : NSObject<NSCopying>
// The mapper for this instance
- (RKObjectMapping *) _mapper;

// The serializer for this instance
- (RKObjectMapping *) _serializer;

- (NSDictionary *)convertToDictionary;

- (NSString *)convertToFormURLEncoded;

- (NSString *)convertToJSON;

- (BOOL)isNew;
@end

@interface MSRestSerializableResource : MSRestSerializable

#pragma mark methods to be overridden

+ (Class) classForResource;

// The resource path. If this 
+ (NSString *) resourcePath;

// Is the resource a singleton or a collection
+ (bool) isSingleton;

// Can the client create resources
+ (bool) canCreate;

// Can the client read resources
+ (bool) canRead;

// Can the client update resources
+ (bool) canUpdate;

// Can the client delete resources
+ (bool) canDelete;

#pragma mark helpers

// The router for this class
+ (RKObjectRouter *) router;

// Intialize the routing module. Must
// be called from +initialize in a 
// subclass or the logic will not
// work.
+ (void) initializeRouting;


// save the object
-(void) saveWithDelegate:(id<RKObjectLoaderDelegate>)delegate;

// Find an instance by id
+ (void) find:(NSNumber *)id 
 withDelegate:(id<RKObjectLoaderDelegate>)delegate;

// Load collection
+ (void) loadCollectionWithDelegate:(id<RKObjectLoaderDelegate>)delegate;

// Load collection with query
+ (void) loadCollectionThroughQuery:(MSRestSerializable *)mappableQueryObject 
                       withDelegate:(id<RKObjectLoaderDelegate>)delegate;

@end
