//
//  ViewController.m
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 14.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

#import "BRViewController.h"
#import "BarcodeParserEAN13.h"

@interface BRViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextViewDelegate>;

@property (strong, nonatomic) IBOutlet UIImageView *loadedImageFromGallery;
@property (strong, nonatomic) IBOutlet UIButton *loadButtonFromGallery;
@property (strong, nonatomic) IBOutlet UITextView *resultAlgorithmTextView;

@end

@implementation BRViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    NSData *dataImageFromGallery = UIImageJPEGRepresentation([info objectForKey:@"UIImagePickerControllerOriginalImage"], 0.6);
    UIImage *imageFromGallery = [[UIImage alloc] initWithData:dataImageFromGallery];
    self.loadedImageFromGallery.image = imageFromGallery;
    self.resultAlgorithmTextView.text = @"Tap analyze button";
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - IBActions
- (IBAction)loadButtonFromGalleryPressedAction:(id)sender {
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    pickerController.allowsEditing = YES;
    [self presentViewController:pickerController animated:YES completion:nil];
}

- (IBAction)startButtonPressed:(id)sender {
    
    BarcodeParserEAN13 *barcodeParser = [[BarcodeParserEAN13 alloc] init];
    NSString *barcodeNumbers = [barcodeParser barcodeFromImage:self.loadedImageFromGallery.image];
    self.resultAlgorithmTextView.text = barcodeNumbers;
    
}

#pragma mark - UITextViewDelegate
- (void)textViewDidChangeSelection:(UITextView *)textView {
    [self.resultAlgorithmTextView resignFirstResponder];
}
@end
