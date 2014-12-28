//
//  UserDataManager.m
//  InstagramAPI-Sample
//
//  Created by Master on 2014/12/28.
//  Copyright (c) 2014年 net.masuhara. All rights reserved.
//

#import "UserDataManager.h"

@implementation UserDataManager

static UserDataManager *sharedData = nil;

- (id)init
{
    self = [super init];
    if (self) {
        //Initialization
        _token           = nil;
        _fullName        = nil;
        _userID          = nil;
        _bio             = nil;
        _profileImageURL = nil;
        _followed        = nil;
        _following       = nil;
        _numberOfPosts   = nil;
        
    }
    return self;
}

+ (UserDataManager *)sharedManager{
    if (!sharedData) {
        sharedData = [UserDataManager new];
    }
    return sharedData;
}


@end
