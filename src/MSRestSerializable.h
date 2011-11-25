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

extern NSDictionary * convertToDictionary( NSObject * object);

extern NSString * convertToFormURLEncoded( NSObject * object);

extern NSString * convertToJSON( NSObject * object);


@protocol MSRestResource

// Is the object new or not
- (BOOL)isNew;

+ (void)initializeRouting;

// Save a single record
-(void) saveWithDelegate:(id<RKObjectLoaderDelegate>)delegate;

// Delete a single record
- (void)deleteWithDelegate:(id<RKObjectLoaderDelegate>)delegate;

// Load a single record
+ (void) loadItem:(NSNumber *)id 
     withDelegate:(id<RKObjectLoaderDelegate>)delegate;

// Load collection
+ (void) loadCollectionWithDelegate:(id<RKObjectLoaderDelegate>)delegate;

// Load collection with query
+ (void) loadCollectionThroughQuery:(NSObject *)mappableQueryObject 
                       withDelegate:(id<RKObjectLoaderDelegate>)delegate;

@end
