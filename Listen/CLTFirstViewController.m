//
//  CLTFirstViewController.m
//  Listen
//
//  Created by Christopher Truman on 10/28/13.
//  Copyright (c) 2013 truman. All rights reserved.
//

#import "CLTFirstViewController.h"
#import <PocketAPI/PocketAPI.h>

@interface CLTFirstViewController ()

@end

@implementation CLTFirstViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setup];

	// Do any additional setup after loading the view, typically from a nib.
    if (![PocketAPI sharedAPI].loggedIn) {
        [[PocketAPI sharedAPI] loginWithHandler: ^(PocketAPI *API, NSError *error){
            if (error != nil)
            {
                // There was an error when authorizing the user.
                // The most common error is that the user denied access to your application.
                // The error object will contain a human readable error message that you
                // should display to the user. Ex: Show an UIAlertView with the message
                // from error.localizedDescription
            }
            else
            {
                // The user logged in successfully, your app can now make requests.
                // [API username] will return the logged-in user’s username
                // and API.loggedIn will == YES
            }
        }];
    }
    else {
        NSString *apiMethod = @"get";
        PocketAPIHTTPMethod httpMethod = PocketAPIHTTPMethodPOST;
        NSDictionary *arguments = @{@"consumer_key": [NSString stringWithFormat:@"%lu", (unsigned long)[PocketAPI sharedAPI].appID], @"detailType" : @"complete"};

        [[PocketAPI sharedAPI] callAPIMethod:apiMethod
                              withHTTPMethod:httpMethod
                                   arguments:arguments
                                     handler: ^(PocketAPI *api, NSString *apiMethod, NSDictionary *response, NSError *error){
                                         // handle the response here
                                         NSArray * articleArray = [response[@"list"] allValues];
                                         for (NSDictionary * articleDictionary in articleArray) {
                                             NSLog(@"%@", articleDictionary[@"resolved_url"]);
                                         }
                                     }];
    }

}

-(void)setup{

[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(pocketLoginStarted:)
                                             name:PocketAPILoginStartedNotification
                                           object:nil];

[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(pocketLoginFinished:)
                                             name:PocketAPILoginFinishedNotification
                                           object:nil];
}

-(void)pocketLoginStarted:(NSNotification *)notification{
    // present login loading UI here
}

-(void)pocketLoginFinished:(NSNotification *)notification{
    // hide login loading UI here
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
