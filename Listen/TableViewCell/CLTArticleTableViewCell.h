//
//  CLTArticleTableViewCell.h
//  Listen
//
//  Created by Hanako Nesbitt on 2/23/14.
//  Copyright (c) 2014 truman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CLTArticleTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageArticleView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabel;

@end
