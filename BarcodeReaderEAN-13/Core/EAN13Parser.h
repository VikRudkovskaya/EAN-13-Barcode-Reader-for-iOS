//
//  EAN13Parser.h
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 20.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

#import <Foundation/Foundation.h>

@class UIImage;

/**
 * В данном классе происходит обработка UIImage, представляющая собой фото штрихкода в формате EAN-13.
 * (Можно попробовать загрузить не штрихкод, но результат обработки будет непредсказуем) 
 * Возвращается отформатированная строка с распознанными\нераспознанными цифрами (13 штук)
 * Нераспознанные цифры вернуться в виде "*"
 */

@interface EAN13Parser : NSObject

- (NSString *)barcodeFromImage:(UIImage *)image;

@end
