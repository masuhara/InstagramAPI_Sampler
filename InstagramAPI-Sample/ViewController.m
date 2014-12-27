//
//  ViewController.m
//  InstagramAPI-Sample
//
//  Created by Master on 2014/12/28.
//  Copyright (c) 2014年 net.masuhara. All rights reserved.
//

#import "ViewController.h"
#import "APIManager.h"
#import "AFNetworking.h"
#import <SimpleAuth.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    SimpleAuth.configuration[@"instagram"] = @{@"client_id":CLIENT_ID, SimpleAuthRedirectURIKey:REDIRECT_URI};
    
    [self loginWithInstagram];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loginWithInstagram{
    [SimpleAuth authorize:@"instagram" completion:^(id responseObject, NSError *error) {
        self.instagramToken = [responseObject valueForKeyPath:@"credentials.token"];
    }];
}


- (IBAction)addInstagramPhotos {
    if (self.instagramToken) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        [manager GET:@"https://api.instagram.com/v1/media/popular" parameters:@{@"access_token":self.instagramToken} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSArray *thumbnails = [responseObject valueForKeyPath:@"data.images.thumbnail.url"];
            
            NSLog(@"thum == %@", thumbnails);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
    } else {
        [SimpleAuth authorize:@"instagram" completion:^(id responseObject, NSError *error) {
            self.instagramToken = [responseObject valueForKeyPath:@"credentials.token"];
            [self addInstagramPhotos];
        }];
    }
}

@end
