//
//  AddFavouriteToEventBO.m
//  Ga2oo
//
//  Created by Suresh on 10/09/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AddFavouriteToEventBO.h"


@implementation AddFavouriteToEventBO

@synthesize Result;


-(id)init
{
	self = [super init];
	return self;
}

-(void)dealloc
{
	[Result release];
	Result = nil;
	[super dealloc];
}

@end
