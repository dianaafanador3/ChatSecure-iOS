//
//  XLFormViewController+ChatSecure.m
//  ChatSecure
//
//  Created by Diana Perez on 7/2/15.
//  Copyright (c) 2015 Chris Ballinger. All rights reserved.
//

#import "XLFormViewController+ChatSecure.h"

@implementation XLFormViewController (ChatSecure)



- (CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 10.0f;
    }
    else if(section == 1)
    {
        return 15.0f;
    }
    
    
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger)section {
    return 1.0;
}

- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}

- (UIView*)tableView:(UITableView*)tableView viewForFooterInSection:(NSInteger)section {
    return [[UIView alloc] initWithFrame:CGRectZero];
}
@end
