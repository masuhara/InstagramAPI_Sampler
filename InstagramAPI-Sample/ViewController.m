//
//  ViewController.m
//  InstagramAPI-Sample
//
//  Created by Master on 2014/12/28.
//  Copyright (c) 2014年 net.masuhara. All rights reserved.
//

#import "ViewController.h"
#import "APIManager.h"
#import "UserDataManager.h"

#import "AFNetworking.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import <SimpleAuth.h>
#import "SVProgressHUD.h"

#define NUMBER_OF_PHOTOS @"48"


@interface ViewController ()
<UICollectionViewDataSource, UICollectionViewDelegate>
{
    NSArray *photoURLArray;
    IBOutlet UICollectionView *popularCollectionView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    popularCollectionView.dataSource = self;
    popularCollectionView.delegate = self;
    
    SimpleAuth.configuration[@"instagram"] = @{@"client_id":CLIENT_ID, SimpleAuthRedirectURIKey:REDIRECT_URI};
    
    [self showInstagramPhotos];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - InstagramAPI

- (void)showInstagramPhotos {
    
    if (self.instagramToken) {
        AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
        
        [manager GET:@"https://api.instagram.com/v1/media/popular" parameters:@{@"access_token":self.instagramToken, @"count":NUMBER_OF_PHOTOS} success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            photoURLArray = [responseObject valueForKeyPath:@"data.images.thumbnail.url"];
            [popularCollectionView reloadData];
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"Error: %@", error);
        }];
        
    } else {
        [self loginWithInstagram];
    }
}


- (void)loginWithInstagram{
    [SimpleAuth authorize:@"instagram" completion:^(id responseObject, NSError *error) {
        self.instagramToken = [responseObject valueForKeyPath:@"credentials.token"];
        [self showInstagramPhotos];
        
        [UserDataManager sharedManager].token = self.instagramToken;
         [UserDataManager sharedManager].userName = [responseObject valueForKeyPath:@"extra.raw_info.data.username"];
        [UserDataManager sharedManager].fullName = [responseObject valueForKeyPath:@"extra.raw_info.data.full_name"];
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
    
    //MARK:Thumbnail
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



@end
