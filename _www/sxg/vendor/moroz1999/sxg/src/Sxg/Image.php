<?php

namespace Sxg;

class Image
{
    const SXG_PALETTE_FORMAT_CLUT = 0;
    const SXG_PALETTE_FORMAT_PWM = 1;
    const SXG_COLOR_FORMAT_16 = 1;
    const SXG_COLOR_FORMAT_256 = 2;
    protected $version = 2;
    protected $backgroundColor = 0;
    protected $packingType = 0;
    protected $rgbPalette;
    protected $paletteType = self::SXG_PALETTE_FORMAT_PWM;

    protected $splittedRgbPalette;
    protected $pixels;
    protected $colorFormat = 1;
    protected $width = 320;
    protected $height = 240;
    protected static $clut = [
        0  => 0,
        1  => 10,
        2  => 21,
        3  => 31,
        4  => 42,
        5  => 53,
        6  => 63,
        7  => 74,
        8  => 85,
        9  => 95,
        10 => 106,
        11 => 117,
        12 => 127,
        13 => 138,
        14 => 149,
        15 => 159,
        16 => 170,
        17 => 181,
        18 => 191,
        19 => 202,
        20 => 213,
        21 => 223,
        22 => 234,
        23 => 245,
        24 => 255,
    ];

    /**
     * @param int $paletteType
     */
    public function setPaletteType($paletteType)
    {
        $this->paletteType = $paletteType;
    }

    /**
     * @return int
     */
    public function getHeight()
    {
        return $this->height;
    }

    /**
     * @param int $height
     */
    public function setHeight($height)
    {
        $this->height = $height;
    }

    /**
     * @return int
     */
    public function getWidth()
    {
        return $this->width;
    }

    /**
     * @param int $width
     */
    public function setWidth($width)
    {
        $this->width = $width;
    }

    /**
     * @return int
     */
    public function getColorFormat()
    {
        return $this->colorFormat;
    }

    /**
     * @param int $colorFormat
     */
    public function setColorFormat($colorFormat)
    {
        $this->colorFormat = $colorFormat;
    }

    /**
     * @return int
     */
    public function getBackgroundColor()
    {
        return $this->backgroundColor;
    }

    /**
     * @param int $backgroundColor
     */
    public function setBackgroundColor($backgroundColor)
    {
        $this->backgroundColor = $backgroundColor;
    }

    /**
     * @return mixed
     */
    public function getRgbPalette()
    {
        return $this->rgbPalette;
    }

    /**
     * @param mixed $palette
     * @return \Sxg\Image
     */
    public function setRgbPalette($palette)
    {
        $this->rgbPalette = $palette;
        $this->splittedRgbPalette = [];
        foreach ($this->rgbPalette as $color) {
            $this->splittedRgbPalette[] = [($color >> 16) & 0xFF, ($color >> 8) & 0xFF, $color & 0xFF, $color];
        }
        return $this;
    }

    public function importFromGd($gdObject)
    {
        if ($gdObject = $this->convertGdObject($gdObject)) {
            $this->readPixelsFromGd($gdObject);
        }
    }

    protected function readPixelsFromGd($gdObject)
    {
        for ($y = 0; $y < $this->height; $y++) {
            for ($x = 0; $x < $this->width; $x++) {
                $this->pixels[] = imagecolorat($gdObject, $x, $y);
            }
        }
    }

    protected function convertGdObject($gdObject)
    {
        //create new object with restricted palette
        $newObject = imagecreate($this->width, $this->height);
        $width = imagesx($gdObject);
        $height = imagesy($gdObject);

        //create separate resource for palette holding.
        //this cannot be created in $newObject unfortunately due to GD conversion bug,
        //so we have to use intermediate object
        $palette = imagecreate($this->width, $this->height);

        //assign sxg palette colors to palette holding resource
        foreach ($this->splittedRgbPalette as $color) {
            imagecolorallocate($palette, $color[0], $color[1], $color[2]);
        }

        //here is the trick: assign palette before copying
        imagepalettecopy($newObject, $palette);
        //copy truecolor source to our new object with resampling. colors get replaced with palette as well.
        imagecopyresampled($newObject, $gdObject, 0, 0, 0, 0, $this->width, $this->height, $width, $height);
        //trick: assign palette after copying as well
        imagepalettecopy($newObject, $palette);

        //        header('Content-type: image/png');
        //        imagepng($newObject);
        //        exit;

        return $newObject;
    }

    public function getSxgData()
    {
        return $this->generateSxgData();
    }

    protected function generateSxgData()
    {
        //        +#0000 #04 #7f+"SXG" - 4 байта сигнатура, что это формат файла SXG
        //        +#0004 #01 1 байт версия формата
        //        +#0005 #01 1 байт цвет фона (используется для очистки)
        //        +#0006 #01 1 байт тип упаковки данных (#00 - данные не пакованы)
        //        +#0007 #01 1 байт формат изображения (1 - 16ц, 2 - 256ц)
        //        +#0008 #02 2 байта ширина изображения
        //        +#000a #02 2 байта высота изображения
        //
        //        (далее указываются смещения, для того, что бы можно было расширить заголовок)
        //        +#000c #02 смещение от текущего адреса до начала данных палитры
        //        +#000e #02 смещение от текущего адреса до начала данных битмап
        //
        //        Собственно начало данных палитры
        //        +#0010 #0200 512 байт палитра
        //
        //        и начало данных битмап
        //        +#0210 #xxxx данные битмап

        $sxgPalette = $this->getSxgPalette();
        $sxgPixels = $this->getSxgPixels();

        $data = chr(0x7F) . 'SXG';
        $data .= chr($this->version);
        $data .= chr($this->backgroundColor);
        $data .= chr($this->packingType);
        $data .= chr($this->colorFormat);

        $data .= $this->littleEndian($this->width);
        $data .= $this->littleEndian($this->height);

        //shift until palette start
        $data .= $this->littleEndian(2);

        //shift until pixels start
        $data .= $this->littleEndian(count($sxgPalette) * 2);
        foreach ($sxgPalette as $sxgColor) {
            $data .= $this->littleEndian($sxgColor);
        }
        foreach ($sxgPixels as $sxgPixelsByte) {
            $data .= chr($sxgPixelsByte);
        }


        return $data;
    }

    protected function littleEndian($integer)
    {
        return chr($integer & 0xFF) . chr($integer >> 8 & 0xFF);
    }

    protected function bigEndian($integer)
    {
        return chr($integer >> 8 & 0xFF) . chr($integer & 0xFF);
    }

    public function getSxgPixels()
    {
        $sxgPixels = [];
        if ($this->colorFormat == self::SXG_COLOR_FORMAT_16) {
            $firstPixel = false;
            foreach ($this->pixels as $pixel) {
                if ($firstPixel === false) {
                    $firstPixel = $pixel;
                } else {
                    $sxgPixels[] = (($firstPixel & 0x1f) << 4) + ($pixel & 0x1f);
                    $firstPixel = false;
                }
            }
        } elseif ($this->colorFormat == self::SXG_COLOR_FORMAT_256) {
            foreach ($this->pixels as $pixel) {
                $sxgPixels[] = $pixel;
            }
        }
        return $sxgPixels;
    }

    public function getSxgPalette()
    {
        $sxgPalette = [];
        if ($this->paletteType == self::SXG_PALETTE_FORMAT_PWM) {
            foreach ($this->splittedRgbPalette as $color) {
                $sxgPalette[] = ($color[0] >> 3 << 10) + ($color[1] >> 3 << 5) + ($color[2] >> 3) + 32768;
            }
        } elseif ($this->paletteType == self::SXG_PALETTE_FORMAT_CLUT) {
            foreach ($this->splittedRgbPalette as $color) {
                $sxgPalette[] = ($this->findClosestClutValue($color[0]) << 10) + ($this->findClosestClutValue($color[1]) << 5) + $this->findClosestClutValue($color[2]);
            }
        }
        return $sxgPalette;
    }

    protected function findClosestClutValue($colorByte)
    {
        $closest = null;
        $closestDifference = PHP_INT_MAX;
        foreach (self::$clut as $sxgColor => $clutValue) {
            if (($difference = abs($colorByte - $clutValue)) < $closestDifference || $closest === null) {
                $closestDifference = $difference;
                $closest = $sxgColor;
            }
        }
        return $closest;
    }
}