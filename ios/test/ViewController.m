//
//  ViewController.m
//  test
//
//  Created by brainpoint on 10/8/15.
//  Copyright © 2015 citong. All rights reserved.
//

#import "ViewController.h"

#import "../include/codeScan.h"

@interface ViewController ()
<
CodeScanDelegate,
UIAlertViewDelegate
>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(onPushView:)];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)onPushView:(id)sender
{
    CodeScanViewController* vc = [[CodeScanViewController alloc] init];
    vc.delegate = self;
    //[vc trunOnTorch:YES];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void) onScanSuccess: (CodeScanViewController*)controller
                  code: (NSString*)code
{
    if (!code)
        return;
    
    [controller stop];
    
    UIAlertController* alertController = [UIAlertController alertControllerWithTitle:@"ok"
                                                                              message:code
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
        [controller start];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}


@end
