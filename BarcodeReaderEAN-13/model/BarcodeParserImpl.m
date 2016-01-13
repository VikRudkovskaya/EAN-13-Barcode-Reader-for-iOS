//
//  BarcodeParserImpl.m
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 20.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//

//-3 ошибка парсера
//-1 не прошел по L-шаблону, может быть ошибка парсера
//-2 не совпало ни с одним шаблоном или ошибка парсера

#import "BarcodeParserImpl.h"

@implementation BarcodeParserImpl

-(NSString*)barcodeFromImage:(UIImage *)image{
    NSUInteger width = image.size.width;
    NSUInteger height = image.size.height;
    int h = round(height / 2 + 5);
    
    NSMutableString *returnStringFromArray = [[NSMutableString alloc] init];
    
// Шаг 1. Подготовка
    // Шаг 1.0 Делаем массив 1-0 из фото
    short **arrayFromImage = [self blackAndWhiteArrayCFromImage:image];
    // Шаг 1.1 Выделяем из массива сканирующую линию
    short *vectorScanLine;
    vectorScanLine = arrayFromImage[h];
    
    // Шаг 1.2 Считаем индексы до значащей части штрихкода - первых и последних двух вертикальных полос
    // (предпоагаю, что с левого и правого края белый фон, т.е. нули)
    int startIndexForBarcode = [self calculateStartIndexOfBarcodeFromVectorScanLine:vectorScanLine withWidth:width];
    int endIndexForBarcode = [self calculateEndIndexOfBarcodeFromVectorScanLine:vectorScanLine withWidth:width];
    // Шаг 1.3 Вычисляем мат ожидание длины элементарного штриха
    float averageCountOfPixelsInSimpleDash = [self calculateAverageCountOfPixelsInSimpleDashWithStartIndex:startIndexForBarcode
                                                                                              WithEndIndex:endIndexForBarcode];

    // Шаг 1.4 В даннный массив (vectorOfBarcodeNumbers) будут записываться распознанные цифры
    short vectorOfBarcodeNumbers[13];
    // Пока ничего не известно о первой цифре, считаем, что локация == 0
    // Первая цифра "распознается" (вычисляется) только по положению трех из шести цифр в левой части штрихкода
    vectorOfBarcodeNumbers[0] = 0;
    
    // Шаг 1.5 Проверка адекватности полученной сканирующей линии; проверям, прошла ли сканирующая линия непосредственно по баркоду
    if (averageCountOfPixelsInSimpleDash <= 0) {
        for (short i = 0; i < 13; i++) {
            vectorOfBarcodeNumbers[i] = -3;// если не прошла, то выдаём -3
            [returnStringFromArray appendFormat:@"%d", vectorOfBarcodeNumbers[i]];
        }
    return returnStringFromArray;
    }

    // Шаг 1.6 Пропускаем первые две вертикальные линии
    startIndexForBarcode = [self calculateStartIndexToSignificantNumbersWithStartIndex:startIndexForBarcode
                                                                    WithVectorScanLine:vectorScanLine];
// Шаг 2 Распознавание
    int shift = 0;
    // В массив bitArrayForSixLeftNumbers будем записывать сжатые в значащий битовый вид со второй по седьмую цифры (первые 6 левых без самой первой)
    short bitArrayForSixLeftNumbers[42];
    
    // Шаг 2.1 Распознаем первые 6 цифр (левые)
    for (int k = 0; k < 6; k++) {
        short *bitArrayForOneNumber;
        bitArrayForOneNumber = [self bitCompressionOfDashInVectorWithVectorScanLine:vectorScanLine
                                                      WithAveragePixelsInSimpleDash:averageCountOfPixelsInSimpleDash
                                                                     WithStartIndex:&startIndexForBarcode];

        for (int i = 0; i <  7; i++) {
            bitArrayForSixLeftNumbers[shift + i] = bitArrayForOneNumber[i];
        }
        shift = shift + 7;
    
        vectorOfBarcodeNumbers[k+1] = [self decodeLeftNumberLWithBitArrayForOneNumber:bitArrayForOneNumber];
    }
    // В случае, если самая первая цифра не 0, то нужно дораспознать оставшиеся нераскодированные 3 цифры
    short decodeTableForRegion[9][3] = {{3,5,6}, {3,4,6},{3,4,5},{2,5,6},{2,3,6},{2,3,4},{2,4,6},{2,4,5},{2,3,5}};
    for (short i = 0; i < 8; i++) {
        if (vectorOfBarcodeNumbers[decodeTableForRegion[i][0]] == -1 && vectorOfBarcodeNumbers[decodeTableForRegion[i][1]] == -1 && vectorOfBarcodeNumbers[decodeTableForRegion[i][2]] == -1) {
            vectorOfBarcodeNumbers[0] = i+1;
            vectorOfBarcodeNumbers[decodeTableForRegion[i][0]] = [self decodeLeftNumberGWithBitArrayForOneNumber:[self cutArrayFromArray:bitArrayForSixLeftNumbers
                                                                                                                               withIndex:decodeTableForRegion[i][0]]];
            vectorOfBarcodeNumbers[decodeTableForRegion[i][1]] = [self decodeLeftNumberGWithBitArrayForOneNumber:[self cutArrayFromArray:bitArrayForSixLeftNumbers
                                                                                                                               withIndex:decodeTableForRegion[i][1]]];
            vectorOfBarcodeNumbers[decodeTableForRegion[i][2]] = [self decodeLeftNumberGWithBitArrayForOneNumber:[self cutArrayFromArray:bitArrayForSixLeftNumbers
                                                                                                                               withIndex:decodeTableForRegion[i][2]]];
        }
    }
    // Прошли первые 6 (или 7, если считать с самой первой, вынесенной за штрихкод) цифр

    // Шаг 2.2 Дошли до центральных длинных вертикальных линий - пропускаем их, это не значащая часть штрихкода
    startIndexForBarcode = [self calculateStartIndexToSignifificanNumbersInRightPartWithStartIndex:startIndexForBarcode
                                                                                WithVectorScanLine:vectorScanLine];
    
    // Шаг 2.3 Распознаем оставшиеся 6 цифр (правые)
    for (int k = 7; k < 13; k++) {
        short *bitArrayForOneNumber;
        bitArrayForOneNumber = [self bitCompressionOfDashInVectorWithVectorScanLine:vectorScanLine
                                                      WithAveragePixelsInSimpleDash:averageCountOfPixelsInSimpleDash
                                                                     WithStartIndex:&startIndexForBarcode];
        vectorOfBarcodeNumbers[k] = [self decodeRightNumberWithBitArrayForOneNumber:bitArrayForOneNumber];
    }
    
// Шаг 3. Конвертируем полученный ответ в строку
    for (int i = 0; i < 13; i++) {
        if (i == 1 || i == 7) {
            [returnStringFromArray appendFormat:@"    %d", vectorOfBarcodeNumbers[i]];
        }
        else{
           [returnStringFromArray appendFormat:@" %d", vectorOfBarcodeNumbers[i]];
        }
    }
    
    return returnStringFromArray;
}



-(short *) cutArrayFromArray:(short *) bitArrayOfSixNumbers withIndex:(int)index{
    short *resArray = calloc(7, sizeof(short));
   // short resArray[7];
    for(int i = 0; i < 7; i++){
        resArray[i] = bitArrayOfSixNumbers[7 * (index - 1) + i];
    }
    return resArray;
}

#define compareWithPattern(arr, pat) ({BOOL res = YES;\
for (int i = 0; i < 7; i++) {\
if (arr[i]!=pat[i]) { res = NO; }\
}\
res;})\


-(short)decodeLeftNumberLWithBitArrayForOneNumber:(short *) bitArrayForOneNumber{
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 0, 1, 1, 0, 1}))) {
        return 0;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 1, 1, 0, 0, 1}))) {
        return 1;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 1, 0, 0, 1, 1}))) {
        return 2;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 1, 1, 1, 0, 1}))) {
        return 3;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 0, 0, 0, 1, 1}))) {
        return 4;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 1, 0, 0, 0, 1}))) {
        return 5;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 0, 1, 1, 1, 1}))) {
        return 6;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 1, 1, 0, 1, 1}))) {
        return 7;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 1, 0, 1, 1, 1}))) {
        return 8;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 0, 1, 0, 1, 1}))) {
        return 9;
    }
    return -1; //-1 сигнализирует о том, что в L-кодировке число не распознано
}

-(short)decodeLeftNumberGWithBitArrayForOneNumber:(short *)bitArrayForOneNumber{
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 0, 0, 1, 1, 1}))) {
        return 0;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 1, 0, 0, 1, 1}))) {
        return 1;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 1, 1, 0, 1, 1}))) {
        return 2;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 0, 0, 0, 0, 1}))) {
        return 3;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 1, 1, 1, 0, 1}))) {
        return 4;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 1, 1, 1, 0, 0, 1}))) {
        return 5;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 0, 0, 1, 0, 1}))) {
        return 6;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 1, 0, 0, 0, 1}))) {
        return 7;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 0, 1, 0, 0, 1}))) {
        return 8;
    }
    if(compareWithPattern(bitArrayForOneNumber, ((short[7]){0, 0, 1, 0, 1, 1, 1}))) {
        return 9;
    }
    return -2;//не совпало ни с одним шаблоном
}

-(short)decodeRightNumberWithBitArrayForOneNumber:(short *)bitArrayForOneNumber{
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 1, 1, 0, 0, 1, 0}))) {
        return 0;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 1, 0, 0, 1, 1, 0}))) {
        return 1;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 1, 0, 1, 1, 0, 0}))) {
        return 2;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 0, 0, 0, 0, 1, 0}))) {
        return 3;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 0, 1, 1, 1, 0, 0}))) {
        return 4;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 0, 0, 1, 1, 1, 0}))) {
        return 5;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 0, 1, 0, 0, 0, 0}))) {
        return 6;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 0, 0, 0, 1, 0, 0}))) {
        return 7;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 0, 0, 1, 0, 0, 0}))) {
        return 8;
    }
    if (compareWithPattern(bitArrayForOneNumber, ((short[7]){1, 1, 1, 0, 1, 0, 0}))) {
        return 9;
    }
    return -1; //-1 сигнализирует о том, что в L-кодировке число не распознано


}



-(short *)bitCompressionOfDashInVectorWithVectorScanLine:(short *) vectorScanLine WithAveragePixelsInSimpleDash:(float)averageCountOfPixelsInSimpleDash WithStartIndex:(int *)startIndexForBarcodeOut{
    short *numberBitsVecTemp = calloc(7, sizeof(short));
    //numberBitsVecTemp = {2,2,2,2,2,2,2};
    for (int i = 0; i < 7; i++) {
        numberBitsVecTemp[i] = 2;
    }
    int bitLengthOfSameDashes = 0;
    int totalLengthOfDashesInNumber = 0;
    short zeroOrOneLabel = 0;
    int shift = 0;
    int startIndexForBarcode = *startIndexForBarcodeOut;
    while (totalLengthOfDashesInNumber < 7) {
        int sameElementsStretchLength = 0;
        while (vectorScanLine[startIndexForBarcode] == zeroOrOneLabel) {
            bitLengthOfSameDashes = bitLengthOfSameDashes + 1;
            startIndexForBarcode = startIndexForBarcode + 1;
        }
        sameElementsStretchLength = round(bitLengthOfSameDashes / averageCountOfPixelsInSimpleDash);
        totalLengthOfDashesInNumber = totalLengthOfDashesInNumber + sameElementsStretchLength;
        
        for (int i = shift; i < totalLengthOfDashesInNumber; i++) {
            numberBitsVecTemp[i] = zeroOrOneLabel;
        }
        
        shift = shift + sameElementsStretchLength;
        bitLengthOfSameDashes = 0;
        zeroOrOneLabel = 1 - zeroOrOneLabel;
    }
    *startIndexForBarcodeOut = startIndexForBarcode;
    return numberBitsVecTemp;
    
}

-(int)calculateStartIndexToSignificantNumbersWithStartIndex:(int)startIndexForBarcode WithVectorScanLine:(short *) vectorScanLine{// дошли до первого темного места (первой длинной полоски, символизирующей начало штрихкода), пропускаем первую черную полоску, вторую белую, третью черную. Ищем значимые цифры. Вероятно, не самый правильный способ это сделать с помощью череды циклов, но зато понятно и не нужно заводить флажок
    while (vectorScanLine[startIndexForBarcode] == 1) {
        startIndexForBarcode++;
    }
    
    while (vectorScanLine[startIndexForBarcode] == 0) {
        startIndexForBarcode++;
    }
    while (vectorScanLine[startIndexForBarcode] == 1) {
        startIndexForBarcode++;
    }
    return startIndexForBarcode;
}

-(int)calculateStartIndexToSignifificanNumbersInRightPartWithStartIndex:(int)startIndexForBarcode WithVectorScanLine:(short *) vectorScanLine{
    int zeroOrOneMarker = 0;
    int middleDashes = 0;
    while (middleDashes < 5) {
        while (vectorScanLine[startIndexForBarcode] == zeroOrOneMarker) {
            startIndexForBarcode = startIndexForBarcode + 1;
        }
        zeroOrOneMarker = 1 - zeroOrOneMarker;
        middleDashes = middleDashes + 1;
    }
    return startIndexForBarcode;
}




-(float)calculateAverageCountOfPixelsInSimpleDashWithStartIndex:(int)startIndexForBarcode WithEndIndex:(int)endIndexForBarcode{
    float averageCountOfPixelsInSimpleDash = (endIndexForBarcode - startIndexForBarcode + 1) / 95.f;
    return averageCountOfPixelsInSimpleDash;
}


-(int)calculateStartIndexOfBarcodeFromVectorScanLine:(short *)vectorScanLine withWidth: (NSUInteger)width{
    int startIndexForBarcode = 0;
    while (vectorScanLine[startIndexForBarcode] == 0 && startIndexForBarcode < width) {
        startIndexForBarcode++;
    }
    return startIndexForBarcode;
}



-(int)calculateEndIndexOfBarcodeFromVectorScanLine:(short *)vectorScanLine withWidth:(NSUInteger) width{
    int endIndexForBarcode = (int)width - 1;
    while (vectorScanLine[endIndexForBarcode] == 0 && endIndexForBarcode > 1) {
        endIndexForBarcode = endIndexForBarcode - 1;
    }
    return endIndexForBarcode;
}


-(short **) blackAndWhiteArrayCFromImage:(UIImage *)image{ //делает из картинки "отчернобеленный" 0-1 массив
    //1.Делаем из исходного UIImage битовую картинку
    //http://www.raywenderlich.com/69855/image-processing-in-ios-part-1-raw-bitmap-modification
    CGImageRef inputCGImage = [image CGImage];
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 *pixels;
    pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));// можно    pixels = calloc(height * width, sizeof(UInt32));
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    //2. Делаем "изображение" (битовую картинку) черно-белым.
    #define Mask8(x) ( (x) & 0xFF )
    #define R(x) ( Mask8(x) )
    #define G(x) ( Mask8(x >> 8 ) )
    #define B(x) ( Mask8(x >> 16) )
    
    //NSLog(@"Brightness of image:");
    //2.1 Считаем средний цвет пикселя
    UInt32 *currentPixel = pixels;
    CGFloat averageColor = 0.f;
    for (NSUInteger index = 1; index <= height*width; index++) {
        UInt32 color = (R(*currentPixel)+G(*currentPixel)+B(*currentPixel))/3.0;
        
        averageColor = averageColor + (color - averageColor)/index;
        
        currentPixel++;
    }
    
    //2.1 end
    short **arrayForImage = calloc(height, sizeof(short*));
    for (int i = 0; i < height; i++) {
        arrayForImage[i] = calloc(width, sizeof(short));
    }
    currentPixel = pixels;
    for (NSUInteger i = 0; i < height; i++) {
        for (NSUInteger j = 0; j < width; j++) {
            UInt32 color = *currentPixel;
            CGFloat color0to255Representation = (R(color)+G(color)+B(color))/3.0;
            if (color0to255Representation > averageColor) {
                arrayForImage[i][j] = 0;
                //printf("%d",arrayForImage[i][j]);
                
            }
            else {
                arrayForImage[i][j] = 1;
                //printf("%d",arrayForImage[i][j]);
            }
            
            currentPixel++;
        }
       // printf("\n");
    //2.end
    }
    free(pixels);
    return arrayForImage;
}


@end
