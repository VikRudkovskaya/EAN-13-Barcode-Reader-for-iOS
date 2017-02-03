//
//  BarcodeParserEAN13.h
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 20.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BarcodeParserProtocol.h"

/* В данном классе происходит обработка UIImage, возвращается отформатированная строка с распознанными\нераспознанными цифрами (13 штук)
 * -4, -5, - некорректное отчернобеливание изображения или в сканирующую линию попал не баркод
 * -3 - сканирущая линия прошла ниже или выше штрихкода
 * -1 - не прошел по L-шаблону, может быть ошибка парсера
 * -2 - не совпало ни с одним шаблоном – ошибка парсера 
 */

@interface BarcodeParserEAN13 : NSObject <BarcodeParserProtocol>

@end
