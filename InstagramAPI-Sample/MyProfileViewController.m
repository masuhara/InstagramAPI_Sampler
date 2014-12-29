//
//  MyProfileViewController.m
//  InstagramAPI-Sample
//
//  Created by Master on 2014/12/28.
//  Copyright (c) 2014年 net.masuhara. All rights reserved.
//

#import "MyProfileViewController.h"
#import "APIManager.h"
#import "UserDataManager.h"

#import "AFNetworking.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SimpleAuth.h>
#import <QuartzCore/QuartzCore.h>

#define NUMBER_OF_PHOTOS @"48"


@interface MyProfileViewController ()
<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray *photoURLArray;
    IBOutlet UIImageView *profileImageView;
    IBOutlet UILabel *numberOfPostsLabel;
    IBOutlet UILabel *numberOfFollowedLabel;
    IBOutlet UILabel *numerrOfFollowingLabel;
    IBOutlet UILabel *userNameLabel;
    IBOutlet UITextView *userDescriptionLabel;
    IBOutlet UICollectionView *myPhotoCollectionView;
}

@end

@implementation MyProfileViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    myPhotoCollectionView.dataSource = self;
    myPhotoCollectionView.delegate = self;
    
    if (![UserDataManager sharedManager].token) {
        SimpleAuth.configuration[@"instagram"] = @{@"client_id":CLIENT_ID, SimpleAuthRedirectURIKey:REDIRECT_URI};
    }
    
    [self setUpViews];
}

- (void)setUpViews
{
    profileImageView.layer.cornerRadius = profileImageView.bounds.size.height/2.0f;
    profileImageView.clipsToBounds = YES;
    
    [profileImageView sd_setImageWithURL:[NSURL URLWithString:[UserDataManager sharedManager].profileImageURL]
                      placeholderImage:[UIImage imageNamed:@"placeholder@2x.png"]
                               options:SDWebImageCacheMemoryOnly
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 
                                 UIApplication *application = [UIApplication sharedApplication];
                                 application.networkActivityIndicatorVisible = NO;
                                 
                                 if (cacheType != SDImageCacheTypeMemory) {
                                     
                                     //Fade Animation
                                     [UIView transitionWithView:profileImageView
                                                       duration:0.3f
                                                        options:UIViewAnimationOptionTransitionCrossDissolve
                                                     animations:^{
                                                         profileImageView.image = image;
                                                     } completion:nil];
                                     
                                 }
                             }];
    
    //TODO:JSONで返ってくる数値をそのままStringとしてブチ込むとLengthエラーになるので直す。
    //numberOfPostsLabel.text = [UserDataManager sharedManager].numberOfPosts;
    //numberOfFollowedLabel.text = [UserDataManager sharedManager].followed;
    //numerrOfFollowingLabel.text = [UserDataManager sharedManager].following;
    userNameLabel.text = [UserDataManager sharedManager].fullName;
    userDescriptionLabel.text = [UserDataManager sharedManager].bio;
    [self showMyPhotos];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - InstagramAPI

- (void)showMyPhotos{
    if ([UserDataManager sharedManager].token) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        
        [manager GET:@"https://api.instagram.com/v1/media/popular" parameters:@{@"access_token":[UserDataManager sharedManager].token, @"count":NUMBER_OF_PHOTOS} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            photoURLArray = [responseObject valueForKeyPath:@"data.images.thumbnail.url"];
            [myPhotoCollectionView reloadData];
            
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
        [self showMyPhotos];
        
        [UserDataManager sharedManager].userName = [responseObject valueForKeyPath:@"extra.raw_info.data.username"];
        [UserDataManager sharedManager].userName = [responseObject valueForKeyPath:@"extra.raw_info.data.full_name"];
        [UserDataManager sharedManager].userID = [responseObject valueForKeyPath:@"extra.raw_info.data.id"];
        [UserDataManager sharedManager].profileImageURL = [responseObject valueForKeyPath:@"extra.raw_info.data.profile_picture"];
        [UserDataManager sharedManager].bio = [responseObject valueForKeyPath:@"extra.raw_info.data.bio"];
        [UserDataManager sharedManager].followed = [responseObject valueForKeyPath:@"extra.raw_info.data.counts.followed_by"];
        [UserDataManager sharedManager].following = [responseObject valueForKeyPath:@"extra.raw_info.data.counts.follows"];
        [UserDataManager sharedManager].numberOfPosts = [responseObject valueForKeyPath:@"extra.raw_info.data.counts.media"];
    }];
}



#pragma mark - CollectionView DataSource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    
    return photoURLArray.count;
}

//Method to create cell at index path
-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UICollectionViewCell *cell;
    
    cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    
    UIImageView *photoImageView = (UIImageView *)[cell viewWithTag:1];
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
    
    return cell;
}

#pragma mark - CollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"tapped cell is == %d-%d",(int)indexPath.section, (int)indexPath.row);
}


#pragma mark - LogOut

- (IBAction)logOut
{
    //TODO:ログアウト処理
     AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:@"https://instagram.com/accounts/logout" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"%@", responseObject);
        [UserDataManager sharedManager].token = nil;
        [self loginWithInstagram];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

@end
