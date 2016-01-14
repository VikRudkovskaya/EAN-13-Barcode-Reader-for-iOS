//
//  BarcodeParserImpl.m
//  BarcodeReaderEAN-13
//
//  Created by Viktoria Rudkovskaya on 20.12.15.
//  Copyright © 2015 Viktoria Rudkovskaya. All rights reserved.
//
// В данном классе происходит обработка UIImage, возвращается отформатированная строка с распознанными\нераспознанными цифрами (13 штук)
// -3 ошибка парсера (сканирущая линия прошла ниже или выше штрихкода)
// -1 не прошел по L-шаблону, может быть ошибка парсера
// -2 не совпало ни с одним шаблоном – ошибка парсера

#import "BarcodeParserImpl.h"

@implementation BarcodeParserImpl

-(NSString*)barcodeFromImage:(UIImage *)image{
// Шаг 1. Подготовка
    NSUInteger height = image.size.height;
    NSUInteger width = image.size.width;
    printf("высота ");
    printf("%d", (int)height);
    printf("\n");
    NSMutableString *returnStringFromArray = [[NSMutableString alloc] init];
    // Шаг 1.1 Задаем исходное значение высоты, на которой пройдет сканирущая линия
    int h = round(height / 2 + 5); // Экспериментальным способом установлено, что + 5 лучше
    // Шаг 1.0 Делаем массив 1-0 из фото
    short **arrayFromImage = [self blackAndWhiteArrayCFromImage:image];
    // Шаг 1.1 Выделяем из массива сканирующую линию
    short *vectorScanLine;
    vectorScanLine = arrayFromImage[h];
// Шаг 2. Распознавание
    short bestRecognizedNumbers[13];
    // Шаг 2.1 Распознаем штрихкод на исходной высоте
    short *recognizedNumbers = [self recognitionAlgorithmWithScanLine:vectorScanLine WithWidth:(int)width];
    for (short i = 0; i < 13; i++) {
        bestRecognizedNumbers[i] = recognizedNumbers[i];
    }
    for(int i = 0; i < 13; i++){
        printf("%d", recognizedNumbers[i]);
    }
    printf("\n");
    // Считаем контрольную сумму для полученных распознанных цифр. Если контрольная сумма корректна, но возвращаем true
    BOOL checkSum = [self checkControlSummOfRecognizedNumbers:recognizedNumbers];
  
    // Смотрим, есть ли нераспознанные цифры в штрихкоде, считаем сколько их.
    short countOfUnrecognizedNumbersInBarcode = [self calculateCountOfUnrecognizedNumbersInBarcodeWithVectorOfRecognizedNumbers:recognizedNumbers];
 //   short countOfUnrecognizedNumbersForBestRecognizedBarcode = countOfUnrecognizedNumbersInBarcode;
    h = round(height / 10); // Задаем новую высоту
    
    while ((countOfUnrecognizedNumbersInBarcode > 0 || checkSum == false) && h < height) {//Если есть нераспознанные цифры или контрольная сумма не сошлась, то запускаем алгоритм распознавания еще раз
        free(recognizedNumbers);
  
        BOOL flag = false;
        int i = 0;
        while (i < width && flag == false) {
            if (vectorScanLine[i] > 0) {// Проверяем, есть ли в строке элементы отличные от нуля. Если строка состоит только из нулей, то нет смысла её проверять вообще
                flag = true;
            }
            i++;
        }
        
        if (flag) {
            while (countOfUnrecognizedNumbersInBarcode > 0 && h < height) {
                printf("%d", h);
                printf("\n");
                vectorScanLine = arrayFromImage[h];
                recognizedNumbers = [self recognitionAlgorithmWithScanLine:vectorScanLine WithWidth:(int)width];
                for(int i = 0; i < 13; i++){
                    printf("%d", recognizedNumbers[i]);
                }
                printf("\n");
                h = h + 50;
                countOfUnrecognizedNumbersInBarcode = [self calculateCountOfUnrecognizedNumbersInBarcodeWithVectorOfRecognizedNumbers:recognizedNumbers];

                
            }
        }
        else {
            h = h + 1;
        }
    }
    
// Шаг 3. Преобразование в строку
    for (int i = 0; i < 13; i++) {
        if (i == 1 || i == 7) {
            [returnStringFromArray appendFormat:@"    %d", recognizedNumbers[i]];
        }
        else{
           [returnStringFromArray appendFormat:@" %d", recognizedNumbers[i]];
        }
    }
    
// Шаг 4. Освобождение памяти
    for (int i = 0; i < height; i++) {
        free(arrayFromImage[i]);
    }
    free(arrayFromImage);
    free(recognizedNumbers);
    return returnStringFromArray;
}

// Метод считает контрольную сумму полученных распознанных цифр. Если сумма корректна, то возвращается true
-(BOOL) checkControlSummOfRecognizedNumbers:(short *)recognizedNumbers{
    int sum = 0;
    for (short i = 0; i < 12; i++) {
        if (i % 2 == 0) {
            sum = sum + recognizedNumbers[i];
        }
        else{
            sum = sum + 3 * recognizedNumbers[i];
        }
    }
    if (10 - sum % 10 == recognizedNumbers[12]) {
        return true;
    }
    return false;
}

// Метод вычисляет количество нераспознанных цифр в штрихкоде
-(short) calculateCountOfUnrecognizedNumbersInBarcodeWithVectorOfRecognizedNumbers:(short *)recognizedNumbers{
    short countOfUnrecognizedNumbersInBarcode = 0;
    for (int i = 1; i < 13; i++) {
        if (recognizedNumbers[i] == -2 || recognizedNumbers[i] == -1 || recognizedNumbers[i] == -3) {
            countOfUnrecognizedNumbersInBarcode++;
        }
    }
    return countOfUnrecognizedNumbersInBarcode;
}

-(short *) recognitionAlgorithmWithScanLine:(short *) vectorScanLine WithWidth:(int) width{
// Шаг 1. Подготовка
    // Шаг 1.1 Считаем индексы до начала и конца штрихкода - первых и последних двух вертикальных полос
    // (предпоагаю, что с левого и правого края белый фон, т.е. нули)
    int startIndexForBarcode = [self calculateStartIndexOfBarcodeFromVectorScanLine:vectorScanLine withWidth:width];
    int endIndexForBarcode = [self calculateEndIndexOfBarcodeFromVectorScanLine:vectorScanLine withWidth:width];
    // Шаг 1.2 Вычисляем мат ожидание длины элементарного штриха
    float averageCountOfPixelsInSimpleDash = [self calculateAverageCountOfPixelsInSimpleDashWithStartIndex:startIndexForBarcode
                                                                                              WithEndIndex:endIndexForBarcode];
    
    // Шаг 1.3 В даннный массив (vectorOfBarcodeNumbers) будут записываться распознанные цифры
    short *vectorOfBarcodeNumbers = calloc(13, sizeof(short));
    // Пока ничего не известно о первой цифре, считаем, что локация == 0
    // Первая цифра "распознается" (вычисляется) только по положению трех из шести цифр в левой части штрихкода
    vectorOfBarcodeNumbers[0] = 0;
    
    // Шаг 1.4 Проверка адекватности полученной сканирующей линии; проверям, прошла ли сканирующая линия непосредственно по баркоду
    if (averageCountOfPixelsInSimpleDash <= 0) {
        for (short i = 0; i < 13; i++) {
            vectorOfBarcodeNumbers[i] = -3;// если не прошла, то выдаём -3
            //[returnStringFromArray appendFormat:@"%d", vectorOfBarcodeNumbers[i]];
        }
        //return returnStringFromArray;
        return vectorOfBarcodeNumbers;
    }
    
    // Шаг 1.5 Пропускаем первые две вертикальные линии
    startIndexForBarcode = [self calculateStartIndexToSignificantNumbersWithStartIndex:startIndexForBarcode
                                                                    WithVectorScanLine:vectorScanLine
                                                                             WithWidth:width];
// Шаг 2 Распознавание
    int shift = 0;
    // В массив bitArrayForSixLeftNumbers будем записывать сжатые в значащий битовый вид со второй по седьмую цифры (первые 6 левых без самой первой)
    short bitArrayForSixLeftNumbers[42];
    
    // Шаг 2.1 Распознаем первые 6 цифр (левые)
    for (int k = 0; k < 6; k++) {
        if (startIndexForBarcode >= width) {
            for (short i = 0; i < 13; i++) {
                vectorOfBarcodeNumbers[i] = -3;// если не прошла, то выдаём -3
            }
            return vectorOfBarcodeNumbers;
        }

        short *bitArrayForOneNumber = [self bitCompressionOfDashInVectorWithVectorScanLine:vectorScanLine
                                                      WithAveragePixelsInSimpleDash:averageCountOfPixelsInSimpleDash
                                                                     WithStartIndex:&startIndexForBarcode];
        
        for (int i = 0; i <  7; i++) {
            bitArrayForSixLeftNumbers[shift + i] = bitArrayForOneNumber[i];
        }
        shift = shift + 7;
        
        vectorOfBarcodeNumbers[k+1] = [self decodeLeftNumberLWithBitArrayForOneNumber:bitArrayForOneNumber];
        free(bitArrayForOneNumber);
    }
    // В случае, если сканирущая линия сама по себе не содержит ошибок (а это может быть, если,
    // например, на картинке "грязь" или это вообще не штрихкод, или отчернобеливание изображения не совсем корректно(т.е. не такое как нам хотелось бы))
    // и при этом самая первая цифра не 0, то нужно дораспознать оставшиеся нераскодированные 3 цифры
    short decodeTableForRegion[9][3] = {{3,5,6}, {3,4,6},{3,4,5},{2,5,6},{2,3,6},{2,3,4},{2,4,6},{2,4,5},{2,3,5}};
    for (short i = 0; i < 8; i++) {
        if (vectorOfBarcodeNumbers[decodeTableForRegion[i][0]] == -1 && vectorOfBarcodeNumbers[decodeTableForRegion[i][1]] == -1 && vectorOfBarcodeNumbers[decodeTableForRegion[i][2]] == -1) {
            vectorOfBarcodeNumbers[0] = i+1;
            short *cutArray = [self cutArrayFromArray:bitArrayForSixLeftNumbers withIndex:decodeTableForRegion[i][0]];
            vectorOfBarcodeNumbers[decodeTableForRegion[i][0]] = [self decodeLeftNumberGWithBitArrayForOneNumber:cutArray];
            free(cutArray);
            cutArray = [self cutArrayFromArray:bitArrayForSixLeftNumbers withIndex:decodeTableForRegion[i][1]];
            vectorOfBarcodeNumbers[decodeTableForRegion[i][1]] = [self decodeLeftNumberGWithBitArrayForOneNumber:cutArray];
            free(cutArray);
            cutArray = [self cutArrayFromArray:bitArrayForSixLeftNumbers withIndex:decodeTableForRegion[i][1]];
            vectorOfBarcodeNumbers[decodeTableForRegion[i][2]] = [self decodeLeftNumberGWithBitArrayForOneNumber:cutArray];
            free(cutArray);
        }
    }
    // Прошли первые 6 (или 7, если считать с самой первой, вынесенной за штрихкод) цифр
    
    // Шаг 2.2 Дошли до центральных длинных вертикальных линий - пропускаем их, это не значащая часть штрихкода
    startIndexForBarcode = [self calculateStartIndexToSignifificanNumbersInRightPartWithStartIndex:startIndexForBarcode
                                                                                WithVectorScanLine:vectorScanLine
                                                                                         WithWidth:(int) width];
    
    // Шаг 2.3 Распознаем оставшиеся 6 цифр (правые)
    for (int k = 7; k < 13; k++) {
        if (startIndexForBarcode >= width) {
            for (short i = 0; i < 13; i++) {
                vectorOfBarcodeNumbers[i] = -3;
            }
            return vectorOfBarcodeNumbers;
        }
        
        short *bitArrayForOneNumber = [self bitCompressionOfDashInVectorWithVectorScanLine:vectorScanLine
                                                      WithAveragePixelsInSimpleDash:averageCountOfPixelsInSimpleDash
                                                                     WithStartIndex:&startIndexForBarcode];
        vectorOfBarcodeNumbers[k] = [self decodeRightNumberWithBitArrayForOneNumber:bitArrayForOneNumber];
        free(bitArrayForOneNumber);
    }
    return vectorOfBarcodeNumbers;
}

-(short *) bitCompressionOfDashInVectorWithVectorScanLine:(short *) vectorScanLine WithAveragePixelsInSimpleDash:(float)averageCountOfPixelsInSimpleDash WithStartIndex:(int *)startIndexForBarcodeOut{
    // В идеальном случае число пикселей в каждой элементарной вертикальной черте можно точно вычислить (пиксельная длина
    // баркода будет кратна 95, соответсвенно на каждую элементарную черту придется одинаковое число пикселей).
    // Но изображения не идеальны - на каждую элементарную черту может приходиться разное количество пикселей.
    // Этот метод учитывает, что изображения "неидеальны", и делает компрессию куска сканирующей линии с учетом этого факта.

    short *numberBitsVecTemp = calloc(7, sizeof(short));
   
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

-(short **) blackAndWhiteArrayCFromImage:(UIImage *)image{ //делает из картинки "отчернобеленный" 0-1 массив
// Шаг 1. Делаем из исходного UIImage битовую картинку
    //http://www.raywenderlich.com/69855/image-processing-in-ios-part-1-raw-bitmap-modification
    CGImageRef inputCGImage = [image CGImage];
    NSUInteger width = CGImageGetWidth(inputCGImage);
    NSUInteger height = CGImageGetHeight(inputCGImage);
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    
    UInt32 *pixels;
    pixels = (UInt32 *) calloc(height * width, sizeof(UInt32));// можно  pixels = calloc(height * width, sizeof(UInt32));
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), inputCGImage);
    
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
// Шаг 2. Делаем "изображение" (битовую картинку) черно-белым.
#define Mask8(x) ( (x) & 0xFF )
#define R(x) ( Mask8(x) )
#define G(x) ( Mask8(x >> 8 ) )
#define B(x) ( Mask8(x >> 16) )
    
    //NSLog(@"Brightness of image:");
    //Шаг 2.1 Считаем средний цвет пикселя
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


-(int)calculateStartIndexToSignificantNumbersWithStartIndex:(int)startIndexForBarcode WithVectorScanLine:(short *) vectorScanLine WithWidth:(int) width{// дошли до первого темного места (первой длинной полоски, символизирующей начало штрихкода), пропускаем первую черную полоску, вторую белую, третью черную. Ищем значимые цифры. Вероятно, не самый правильный способ это сделать с помощью череды циклов, но зато понятно
    while (vectorScanLine[startIndexForBarcode] == 1 && startIndexForBarcode < width) {
        startIndexForBarcode++;
    }
    
    while (vectorScanLine[startIndexForBarcode] == 0 && startIndexForBarcode < width) {
        startIndexForBarcode++;
    }
    while (vectorScanLine[startIndexForBarcode] == 1 && startIndexForBarcode < width) {
        startIndexForBarcode++;
    }
    return startIndexForBarcode;
}
-(int)calculateStartIndexToSignifificanNumbersInRightPartWithStartIndex:(int)startIndexForBarcode WithVectorScanLine:(short *) vectorScanLine WithWidth:(int)width{
    int zeroOrOneMarker = 0;
    int middleDashes = 0;
    while (middleDashes < 5 && startIndexForBarcode < width) {
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

@end