//
//  BarcodeParserEAN13.h
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 20.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BarcodeParserProtocol.h"

/* В данном классе происходит обработка UIImage, представляющая собой фото штрихкода в формате EAN-13.
 * (Можно попробовать загрузить не штрихкод, но результат обработки будет непредсказуем) 
 * Возвращается отформатированная строка с распознанными\нераспознанными цифрами (13 штук)
 * Нераспознанные цифры вернуться в виде "*"
 */

@interface BarcodeParserEAN13 : NSObject <BarcodeParserProtocol>

@end
