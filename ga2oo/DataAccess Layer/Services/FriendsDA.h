//
//  tblFriendsDA.h
//  Ga2oo
//
//  Created by Mayank Goyal on 04/05/11.
//  Copyright 2011 Winit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataAccessLayer.h"
#import "Friends.h"

@interface FriendsDA : DataAccessLayer {

}
-(void)DeleteObject:(BaseCoreDataObject*)object;

@end
