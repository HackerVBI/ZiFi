<?php
if (class_exists('ZipArchive')) {
    if (isset($_GET['f'])) {
        $currentPath = dirname(__FILE__);
        $temporaryPath = $currentPath . '/ziptmp/';
        if (!is_dir($temporaryPath)) {
            mkdir($temporaryPath);
        }
        $fileParameter = $_GET['f'];
        $filePath = $currentPath . '/' . $fileParameter;
        if (is_file($filePath)) {
            $zip = new ZipArchive();
            if ($res = $zip->open($filePath)) {
                for ($i = 0; $i < $zip->numFiles; $i++) {
                    if ($fileName = $zip->getNameIndex($i)) {
                        if ($extension = pathinfo($fileName, PATHINFO_EXTENSION)) {
                            $extension = strtolower($extension);
                            if ($extension == 'scl' || $extension == 'trd' || $extension == 'spg') {
                                $file = $zip->extractTo($temporaryPath, [$fileName]);
                                readfile($temporaryPath . $fileName);
                                unlink($temporaryPath . $fileName);
                                exit;
                            }
                        }
                    }
                }

            }
        }
    }else {
        die ('no file');
    }
} else {
    die ('no ZipArchive support');
}