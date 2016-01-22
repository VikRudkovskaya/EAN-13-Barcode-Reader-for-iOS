//
//  ViewController.m
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 14.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

#import "ViewController.h"
#import "BarcodeParserImpl.h"


@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>;

@property (strong, nonatomic) IBOutlet UIButton *loadButtonFromGallery;
@property (strong, nonatomic) IBOutlet UIImageView *loadedImageFromGallery;
@property (strong, nonatomic) IBOutlet UILabel *resultAlgorithmLabel;
@property (assign) CGFloat t;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
       // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loadButtonFromGalleryPressedAction:(id)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerController.allowsEditing = YES;
    [self presentViewController:pickerController animated:YES completion:nil];
    
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info{
    NSData *dataImageFromGallery = UIImageJPEGRepresentation([info objectForKey:@"UIImagePickerControllerOriginalImage"], 0.6);
    //NSLog(@"%@", dataImageFromGallery);
    UIImage *imageFromGallery = [[UIImage alloc] initWithData:dataImageFromGallery];
    self.loadedImageFromGallery.image = imageFromGallery;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)startButtonPressed:(id)sender {
    BarcodeParserImpl *barcodeParser = [[BarcodeParserImpl alloc] init];
    NSString *str = [barcodeParser barcodeFromImage:self.loadedImageFromGallery.image];
    //NSLog(@"%@",str);
   self.resultAlgorithmLabel.text = str;
}


@end
