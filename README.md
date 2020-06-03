# EAN-13 Reader for iOS

![Build Status](https://travis-ci.org/VikRudkovskaya/iOSBarcodeReaderEAN13.svg?branch=master)

Небольшое ios-приложение, демонстрирующее возможности алгоритма распознавания штриховых кодов в формате EAN-13 с реальных фотографий. После загрузки фотографии штрихкода из галереи,  алгоритм автоматически запустится, а результат отобразится под фото. Алгоритм построен на анализе битовой карты, полученной из предоставленного изображения.

![Иллюстрация к проекту](https://github.com/VikRudkovskaya/iOSBarcodeReaderEAN13/raw/master/Screenshots/barcode-ex-img.png)


##  Constrains [Ограничения]

Note that the algorithm analyzes the bitmap from left to right. Therefore, it only works with photographs of a certain kind. The left side of the image must begin with a white area. Otherwise, the algorithm will not work correctly.

[Обратите внимание, что алгоритм в текущем своем исполнении анализирует битовое изображение слева направо. Он работает только с фотографиями определенного вида. Левая сторона изображения обязана начинаться с белой области, то есть визуальный мусор должен быть предварительно обрезан. В противном случае, алгоритм не будет работать корректно.]

![Корректное и некорректное распознавание](https://github.com/VikRudkovskaya/iOSBarcodeReaderEAN13/raw/master/Screenshots/images-constraints.jpg)

Images suitable for the algorithm are given in the Resources -> Examples -> Real-Photos folder.
[Подходящие под алгоритм изображения приведены в папке Resources -> Examples -> Real-Photos.]

## Additional [Дополнительно]

Логика распознавания находится в Core -> EAN13Parser. Работоспособность алгоритма можно протестировать на изображениях, находящихся в папке Resources -> Examples

Для понимания специфики работы Core необходимо ознакомиться с теорией: [как устроены штрих-коды EAN-13](http://www.rion.ru/information/articles/general-barcode/)

Преобразование к черно-белой битовой картинке: [bitmap](https://www.raywenderlich.com/69855/image-processing-in-ios-part-1-raw-bitmap-modification) 



