//
//  FriendTableCell.h
//  Ga2oo
//
//  Created by Mayank Goyal on 14/02/11.
//  Copyright 2011 Winit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Ga2ooAppDelegate.h"
#import "FriendsBO.h"

@interface FriendTableCell : UITableViewCell {

	UILabel *lblTitle;
	UIImageView *imgViewEvent;
	FriendsBO *objUser;
	UIImageView *imgViewDarkBG;
	UIImageView *imgViewDarkBGSel;
	UIView *viewSelectedBackgroundView;
	UIView *viewBackgroundView;	
	
	NSThread *_thread;
	UIActivityIndicatorView *loaderView;
	UIImage *imgCoverImg;
    
    UIButton *btnAdd;
}
@property (nonatomic, retain) UIButton *btnAdd;
@property (nonatomic, retain) UILabel *lblTitle;
@property (nonatomic, retain) UIImageView *imgViewEvent;
@property (nonatomic, retain) UIImageView *imgViewDarkBG;
@property (nonatomic, retain) UIImageView *imgViewDarkBGSel;
@property (nonatomic, retain) UIActivityIndicatorView *loaderView;

-(FriendsBO *)getTips;
- (void)setTips:(FriendsBO *)item ;

-(void)showUserImage;
-(void)setimage:(UIImage *)image ;

@end
