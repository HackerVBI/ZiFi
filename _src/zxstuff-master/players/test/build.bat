FOR %%i IN (test_*.asm) DO ..\tools\sjasmplus -I.. -I../samples --lstlab --lst=%%~ni.lst %%i > %%~ni.log
