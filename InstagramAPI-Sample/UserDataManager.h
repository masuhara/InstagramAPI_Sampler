//
//  UserDataManager.h
//  InstagramAPI-Sample
//
//  Created by Master on 2014/12/28.
//  Copyright (c) 2014年 net.masuhara. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UserDataManager : NSObject

@property (nonatomic)NSString *token;
@property (nonatomic)NSString *fullName;
@property (nonatomic)NSString *userName;
@property (nonatomic)NSString *userID;
@property (nonatomic)NSString *bio;
@property (nonatomic)NSString *profileImageURL;
@property (nonatomic)NSString *followed;
@property (nonatomic)NSString *following;
@property (nonatomic)NSString *numberOfPosts;


+ (UserDataManager *)sharedManager;

@end
