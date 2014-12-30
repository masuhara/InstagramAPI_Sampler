//
//  HomeViewController.m
//  InstagramAPI-Sample
//
//  Created by Master on 2014/12/30.
//  Copyright (c) 2014年 net.masuhara. All rights reserved.
//

#import "HomeViewController.h"
#import "APIManager.h"
#import "UserDataManager.h"

#import "AFNetworking.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SimpleAuth.h>
#import "SVProgressHUD.h"

#define NUMBER_OF_PHOTOS @"20"


@interface HomeViewController ()
<UITableViewDataSource, UITableViewDelegate>
{
    NSArray *allObjects;
    NSArray *photoURLArray;
    NSArray *userNameArray;
    NSArray *createdTimeArray;
    NSArray *profileURLArray;
    NSArray *numberOfLikeArray;
    NSArray *idArray;
    
    IBOutlet UITableView *homeTableView;
}

@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    homeTableView.dataSource = self;
    homeTableView.delegate = self;
    homeTableView.allowsMultipleSelection = YES;
    
    SimpleAuth.configuration[@"instagram"] = @{@"client_id":CLIENT_ID, SimpleAuthRedirectURIKey:REDIRECT_URI};
    
    [self showInstagramPhotos];
}

- (void)viewWillAppear:(BOOL)animated
{
    if (self.tabBarController.tabBar.hidden == YES) {
        self.tabBarController.tabBar.hidden = NO;
    }
}






- (void)showInstagramPhotos {
    
    if (![SVProgressHUD isVisible]) {
        [SVProgressHUD showWithStatus:@"読み込み中..." maskType:SVProgressHUDMaskTypeBlack];
    }
    
    
    if ([UserDataManager sharedManager].token) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        
        [manager GET:@"https://api.instagram.com/v1/users/self/feed" parameters:@{@"access_token":[UserDataManager sharedManager].token, @"count":NUMBER_OF_PHOTOS} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            allObjects = [responseObject valueForKey:@"data"];
            
            photoURLArray = [responseObject valueForKeyPath:@"data.images.standard_resolution.url"];
            userNameArray = [responseObject valueForKeyPath:@"data.caption.from.full_name"];
            createdTimeArray = [responseObject valueForKeyPath:@"data.caption.created_time"];
            profileURLArray = [responseObject valueForKeyPath:@"data.caption.from.profile_picture"];
            numberOfLikeArray = [responseObject valueForKeyPath:@"data.likes.count"];
            idArray = [responseObject valueForKeyPath:@"data.id"];
            
            if ([SVProgressHUD isVisible]) {
                [SVProgressHUD dismiss];
            }
            
            [homeTableView reloadData];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
    } else {
        [self loginWithInstagram];
    }
}

- (void)loginWithInstagram{
    [SimpleAuth authorize:@"instagram" completion:^(id responseObject, NSError *error) {
        [UserDataManager sharedManager].token = [responseObject valueForKeyPath:@"credentials.token"];
        [UserDataManager sharedManager].userName = [responseObject valueForKeyPath:@"extra.raw_info.data.username"];
        [UserDataManager sharedManager].fullName = [responseObject valueForKeyPath:@"extra.raw_info.data.full_name"];
        [UserDataManager sharedManager].userID = [responseObject valueForKeyPath:@"extra.raw_info.data.id"];
        [UserDataManager sharedManager].profileImageURL = [responseObject valueForKeyPath:@"extra.raw_info.data.profile_picture"];
        [UserDataManager sharedManager].bio = [responseObject valueForKeyPath:@"extra.raw_info.data.bio"];
        [UserDataManager sharedManager].followed = [responseObject valueForKeyPath:@"extra.raw_info.data.counts.followed_by"];
        [UserDataManager sharedManager].following = [responseObject valueForKeyPath:@"extra.raw_info.data.counts.follows"];
        [UserDataManager sharedManager].numberOfPosts = [responseObject valueForKeyPath:@"extra.raw_info.data.counts.media"];
        
        [self showInstagramPhotos];
    }];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - TableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return allObjects.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    //MARK:UserImage
    UIImageView *userImageView = (UIImageView *)[cell viewWithTag:1];
    userImageView.layer.cornerRadius = userImageView.bounds.size.height/2.0f;
    userImageView.clipsToBounds = YES;
    
    [userImageView sd_setImageWithURL:profileURLArray[indexPath.row]
                      placeholderImage:[UIImage imageNamed:@"placeholder@2x.png"]
                               options:SDWebImageCacheMemoryOnly
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 
                                 UIApplication *application = [UIApplication sharedApplication];
                                 application.networkActivityIndicatorVisible = NO;
                                 
                                 if (cacheType != SDImageCacheTypeMemory) {
                                     
                                     //Fade Animation
                                     [UIView transitionWithView:userImageView
                                                       duration:0.3f
                                                        options:UIViewAnimationOptionTransitionCrossDissolve
                                                     animations:^{
                                                         userImageView.image = image;
                                                     } completion:nil];
                                     
                                 }
                             }];
    
    //MARK:Photo
    UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:2];
    
    [photoImageView sd_setImageWithURL:photoURLArray[indexPath.row]
                      placeholderImage:[UIImage imageNamed:@"placeholder@2x.png"]
                               options:SDWebImageCacheMemoryOnly
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 
                                 UIApplication *application = [UIApplication sharedApplication];
                                 application.networkActivityIndicatorVisible = NO;
                                 
                                 if (cacheType != SDImageCacheTypeMemory) {
                                     
                                     //Fade Animation
                                     [UIView transitionWithView:photoImageView
                                                       duration:0.3f
                                                        options:UIViewAnimationOptionTransitionCrossDissolve
                                                     animations:^{
                                                         photoImageView.image = image;
                                                     } completion:nil];
                                     
                                 }
                             }];
    
    
    UILabel *userNameLabel = (UILabel *)[cell viewWithTag:3];
    userNameLabel.text = userNameArray[indexPath.row];
    
    UILabel *createdTimeLabel = (UILabel *)[cell viewWithTag:4];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy/MM/dd/HH:mm";
    NSString *formattedDateString = [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[createdTimeArray[indexPath.row] intValue]]];
    createdTimeLabel.text = formattedDateString;
    
    UILabel *numberOfLikeLabel = (UILabel *)[cell viewWithTag:5];
    numberOfLikeLabel.text = [NSString stringWithFormat:@"♡%@件", numberOfLikeArray[indexPath.row]];
    
    //MARK:Like Button
    UIButton *likeButton = (UIButton *)[cell viewWithTag:6];
    [likeButton addTarget:self action:@selector(postLike:event:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}


#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}




#pragma mark - Like

- (void)postLike:(UIButton *)button event:(id)event
{
    NSSet *touches = [event allTouches];
    UITouch *touch = [touches anyObject];
    CGPoint currentTouchPosition = [touch locationInView:homeTableView];
    NSIndexPath *indexPath = [homeTableView indexPathForRowAtPoint: currentTouchPosition];
    if (indexPath != nil) {
        NSLog(@"indexPath");
    }
    
    if ([UserDataManager sharedManager].token) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        
        NSString *mediaID = [NSString stringWithFormat:@"https://api.instagram.com/v1/media/%@/likes", idArray[indexPath.row]];

        //MARK:POST Like
        [manager POST:mediaID parameters:@{@"access_token":[UserDataManager sharedManager].token} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"%@", responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error.description);
        }];
        
        
        //MARK:DELETE Like
        /*
        [manager DELETE:mediaID parameters:@{@"access_token":[UserDataManager sharedManager].token} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            NSLog(@"%@", responseObject);
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
         */
        
    } else {
        [self loginWithInstagram];
    }
}




@end
