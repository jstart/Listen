//
//  CLTArticleTableViewCell.m
//  Listen
//
//  Created by Hanako Nesbitt on 2/23/14.
//  Copyright (c) 2014 truman. All rights reserved.
//

#import "CLTArticleTableViewCell.h"

@implementation CLTArticleTableViewCell

- (id) initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self.imageArticleView setClipsToBounds:YES];
        [self.imageArticleView setContentMode:UIViewContentModeScaleAspectFill];
    }
    return self;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
