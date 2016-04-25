<?php
$allowedHosts = [
    'zxaaa.untergrund.net',
    'vtrdos.ru',
    'prods.tslabs.info',
    'forum.tslabs.info',
    'zx.kaniv.net',
    'events.retroscene.org',
    'ftp.cc.org.ru',
    'files.scene.org',
    'trd.speccy.cz',
    'localhost',
];
if (isset($_GET['f'])) {
    $currentPath = dirname(__FILE__);
    $temporaryPath = $currentPath . '/ziptmp/';

    if (!is_dir($temporaryPath)) {
        mkdir($temporaryPath);
        chmod($temporaryPath, 0777);
    }

    $remotePath = str_replace(' ', '%20', $_GET['f']);
    $remotePath = str_replace('+', '%2B', $remotePath);
    $parse = parse_url($remotePath);
    if (in_array($parse['host'], $allowedHosts)) {
        if ($remoteName = pathinfo($remotePath, PATHINFO_BASENAME)) {
            if ($content = file_get_contents($remotePath)) {
                $filePath = $temporaryPath . $remoteName;
                file_put_contents($filePath, $content);
                chmod($filePath, 0777);
                if (is_file($filePath)) {
                    if ($extension = pathinfo($filePath, PATHINFO_EXTENSION)) {
                        $extension = strtolower($extension);
                    }
                    if ($extension == '7z' || $extension == 'rar' || $extension == 'zip') {
                        include_once('PHP-SevenZipArchive-master/SevenZipArchive.php');
                        $archive = new SevenZipArchive($filePath, ['binary'=>'7za']);
                        $foundFilePath = false;
                        foreach ($archive as $info) {
                            $archiveFilePath = $info['Name'];
                            if ($extension = pathinfo($archiveFilePath, PATHINFO_EXTENSION)) {
                                $folder = pathinfo($archiveFilePath, PATHINFO_DIRNAME);
                                $fileName = pathinfo($archiveFilePath, PATHINFO_BASENAME);
                                $extension = strtolower($extension);
                                if ($extension == 'scl' || $extension == 'trd' || $extension == 'spg') {
                                    if ($folder == '.'){
                                        $foundFilePath = $archiveFilePath;
                                        break;
                                    } elseif (!$foundFilePath){
                                        $foundFilePath = $archiveFilePath;
                                    }
                                }
                            }
                        }
                        if ($foundFilePath) {
                            $extension = strtolower(pathinfo($foundFilePath, PATHINFO_EXTENSION));
                            $fileName = pathinfo($foundFilePath, PATHINFO_BASENAME);

                            $file = $archive->extractTo($temporaryPath, $foundFilePath);
                            echo '.' . $extension;
                            readfile($temporaryPath . $fileName);
                            unlink($temporaryPath . $fileName);
                            unlink($filePath);
                            exit;
                        }
                    }
                }

            }
        }
    } else {
        die ('no file');
    }
}