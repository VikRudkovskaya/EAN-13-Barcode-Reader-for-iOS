//
//  AnalyzeImageViewController.m
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 14.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

#import "AnalyzeImageViewController.h"
#import "EAN13Parser.h"

@interface AnalyzeImageViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>;

@property (weak, nonatomic) IBOutlet UIButton *attachPhotoButton;
@property (weak, nonatomic) IBOutlet UIImageView *barcodeImageView;
@property (weak, nonatomic) IBOutlet UIView *resultContainerView;
@property (weak, nonatomic) IBOutlet UILabel *resultLabel;

@end

@implementation AnalyzeImageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *, id> *)info {
    
    NSData *dataImageFromGallery = UIImageJPEGRepresentation([info objectForKey:@"UIImagePickerControllerOriginalImage"], 0.6);
    UIImage *imageFromGallery = [[UIImage alloc] initWithData:dataImageFromGallery];
    self.barcodeImageView.image = imageFromGallery;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self parseImage:imageFromGallery];
}

#pragma mark - IBActions

- (IBAction)newBarcodeImageTouchUpInside:(UIButton *)sender {
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerController.allowsEditing = YES;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (IBAction)shareTouchUpInside:(UIButton *)sender {
    
}

#pragma mark - Support

- (void)parseImage:(UIImage *)image {
    EAN13Parser *barcodeParser = [[EAN13Parser alloc] init];
    NSString *barcodeNumbers = [barcodeParser barcodeFromImage:image];
    self.resultLabel.text = barcodeNumbers;
    self.resultContainerView.hidden = NO;
}

@end
