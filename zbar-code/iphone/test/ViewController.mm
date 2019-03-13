//
//  ViewController.m
//  test
//
//  Created by brainpoint on 14-8-7.
//
//

#import "ViewController.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *btn;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onBtn:(id)sender {
    QRCodeViewController* reader = [QRCodeViewController new];
    reader.delegate = (id<QRCodeDelegate>)self;
    [reader useDefaultCameraOverlayView];
    [reader setScanRectWidth:260];
    [self presentViewController:reader animated:YES completion:nil];
}


/**
 * QRCodeDelegate */

- (void) onScanFail: (QRCodeViewController*)controller
{
}

- (void) onScanCancel: (QRCodeViewController*)controller
{
}

- (void) onScanSuccess: (QRCodeViewController*)controller
                  code:(NSString *)code
{
    [controller cancel];
    _btn.titleLabel.text = code;
    [_btn autoresizesSubviews];
}

@end
