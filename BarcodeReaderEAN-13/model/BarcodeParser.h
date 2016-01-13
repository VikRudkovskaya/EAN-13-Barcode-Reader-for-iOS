//
//  BarcodeParser.h
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 19.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol BarcodeParser <NSObject>

- (NSString *) barcodeFromImage: (UIImage *) image;
@end
