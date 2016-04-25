<?php

include_once('vendor/autoload.php');
$url = false;
if (isset($_GET['u'])) {
    $url = $_GET['u'];
}
$width = 320;
if (isset($_GET['w'])) {
    $width = (int)$_GET['w'];
}
$height = 240;
if (isset($_GET['h'])) {
    $height = (int)$_GET['h'];
}
if ($url) {
    $currentPath = dirname(__FILE__);
    $temporaryPath = $currentPath . '/images/' . rand() . time() . '/';

    if (!is_dir($temporaryPath)) {
        mkdir($temporaryPath, 0777, true);
    }
    if ($content = file_get_contents($url)) {
        $originalImage = $temporaryPath . 'src';
        file_put_contents($originalImage, $content);
        $sizes = getimagesize($originalImage);

        $gd = false;
        if ($sizes['mime'] == 'image/jpeg') {
            $gd = imagecreatefromjpeg($originalImage);
        } elseif ($sizes['mime'] == 'image/png') {
            $gd = imagecreatefrompng($originalImage);
        } elseif ($sizes['mime'] == 'image/gif') {
            $gd = imagecreatefromgif($originalImage);
        }
        if ($gd) {
            $image = new Sxg\Image();
            $image->setWidth($width);
            $image->setHeight($height);
            $array = [
                0x000000,
                0x0000ff,
                0xff0000,
                0xff00ff,

                0x00ff00,
                0x00ffff,
                0xffff00,
                0xffffff,

                0x000000,
                0x0000cd,
                0xcd0000,
                0xcd00cd,

                0x00cd00,
                0x00cdcd,
                0xcdcd00,
                0xcdcdcd,
            ];
            $image->setColorFormat($image::SXG_COLOR_FORMAT_16);
            $image->setRgbPalette($array);
            $image->setPaletteType($image::SXG_PALETTE_FORMAT_CLUT);
            $image->importFromGd($gd);
            http_response_code(200);
            header('Content-type: image/sxg');
            header('Content-disposition: inline; filename="generated.sxg"');
            echo $image->getSxgData();
        } else {
            http_response_code(400);
        }
        unlink($originalImage);
    } else {
        http_response_code(400);
    }
    if (is_dir($temporaryPath)){
        rmdir($temporaryPath);
    }
}