# SXG
This repository contains the tools required for SXG images generation in PHP.

## Usage example
```php
$gd = imagecreatefromjpeg('boobs.jpg');

include_once('src/Sxg/Image.php');
$image = new Sxg\Image();
$image->setWidth(320);
$image->setHeight(240);
$array = [
    0x000fff,
    0xff00ff,
    0x000000,
    0xff0000,
    0xffff00,
    0xffffff,
    0xf0ff30,
    0x808080,
    0x80f080,
    0xcdcdcd,
    0xf7cdb4,
    0x432118,
    0xb58169,
];
$image->setColorFormat($image::SXG_COLOR_FORMAT_16);
$image->setRgbPalette($array);
$image->setPaletteType($image::SXG_PALETTE_FORMAT_CLUT);
$image->importFromGd($gd);
file_put_contents('test.sxg', $image->getSxgData());
```
## Installation
Composer
```json
{
    "require": {
		"moroz1999/sxg": "*"
    }
}
```

## Links
- ["SXG Format description"](http://tslabs.info/forum/viewtopic.php?f=25&t=526) - *in Russian*
- ["Video modes and architecture of TS-Config on ZX Evolution"](http://tslabs.info/forum/viewtopic.php?f=35&t=178) - *in Russian*

## License
Creative Commons Zero v1.0 Universal
