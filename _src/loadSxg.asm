;---------------------------------------
; CLi² (Command Line Interface)
; 2013,2015 © breeze/fishbone crew
;---------------------------------------
; SXG file loader
;---------------------------------------

sxgBufferSize	equ	16					; 16*512 = 8192 Размер буфера в блоках по (512кб)

		org	#c000-4
		
		include "system/constants.asm"			; Константы
		include "system/api.h.asm"			; Список комманд CLi² API
		include "system/errorcodes.asm"			; коды ошибок
		include "drivers/drivers.h.asm"			; Список комманд Drivers API
appStart
		db	#7f,"CLA"				; Command Line Application
;---------------------------------------------
		xor	a
		ld	(sxgFileCheck+1),a
		ld	(setViewerMode+1),a

		ld	a,#02
		ld	(widthLoop+2),a

		ld	a,#10
		ld	(setVBank+1),a

		ex	de,hl
		ld	a,eatSpaces
		call	cliKernel
		ex	de,hl

		ld	a,(hl)
		cp	#00
		jp	z,sxgShowInfo				; Выход. Вывод информации о программе

		ex	de,hl
		ld	a,eatSpaces
		call	cliKernel
		ex	de,hl

		ld	de,keyTable
		ld	a,checkCallKeys
		call	cliKernel

		cp	#ff
		jp	z,sxgShowInfo				; Выход. Вывод информации о программе
		
		ld	a,(hl)
		cp	#00
		jp	nz,sxgContinue

sxgFileCheck	ld	a,#00
		cp	#01
		jp	z,setViewerMode
		jp	fileNotSet				; Выход. Не задан файл

sxgContinue	ex	de,hl
		ld	a,eatSpaces
		call	cliKernel
		ld	hl,fileNotFound_1+1
		ld	(hl),de
		ex	de,hl

		ld	de,sxgBuffer
		ld	b,sxgBufferSize
		ld	a,loadFileParts				; Загружаем первую часть в буфер
		call	cliKernel
		cp	#ff					; Если на выходе #ff = ошибка
		jp	z,fileNotFound

;---------------
		ld	hl,sxgBuffer
		ld	a,(hl)
		cp	#7f					; Сигнатура #7f + SXG
		jp	nz,wrongFile
		
		inc	hl
		ld	a,(hl)
		cp	"S"
		jp	nz,wrongFile

		inc	hl
		ld	a,(hl)
		cp	"X"
		jp	nz,wrongFile

		inc	hl
		ld	a,(hl)
		cp	"G"
		jp	nz,wrongFile

;---------------
		push	hl
		ld	hl,sxgFormatMsg
		call	sxgPrint
		pop	hl

;---------------
		inc	hl					; версия формата SXG
		ld	a,(hl)
		push	af
		push	hl
		push	af
		ld	hl,sxgVerMsg
		call	sxgPrint
		pop	af
		ld	de,sxgNumberMsg
		ld	h,#00
		ld	l,a
		ld	a,fourbit2str
		call	cliKernel
		ld	hl,sxgNumberMsg
		call	sxgPrint
		pop	hl
		pop	af					; TODO: Сделать проверку!!

;---------------
		inc	hl					; цвет фона для очистки
		ld	a,(hl)
; 		push	af
		ld	(clrColor+1),a
		push	hl
		push	af
		ld	hl,sxgBgMsg
		call	sxgPrint
		pop	af
		ld	de,sxgNumberMsg
		ld	h,#00
		ld	l,a
		ld	a,fourbit2str
		call	cliKernel
		ld	hl,sxgNumberMsg
		call	sxgPrint
		pop	hl


		
;---------------
		inc	hl					; Тип упаковки данных (#00 - не пакованы)
		ld	a,(hl)
		push	af
		push	hl
		push	af
		ld	hl,sxgPackMsg
		call	sxgPrint
		pop	af
		ld	de,sxgNumberMsg
		ld	h,#00
		ld	l,a
		ld	a,fourbit2str
		call	cliKernel
		ld	hl,sxgNumberMsg
		call	sxgPrint
		pop	hl
		pop	af
								; TODO: Сделать проверку!!
;---------------

		push	hl
		ld	hl,sxgTypeMsg
		call	sxgPrint
		pop	hl

		inc	hl
		ld	a,(hl)
		ld	(imageMode),a
		push	hl
		call	setImageMode
		pop	hl

		cp	#ff					; error -> exit
		ret	z

;---------------
sxgVMem		ld	b,#01
; 		pop	af
; 		ld	c,a					
clrColor	ld	c,#00					; номер цвета
		ld	a,clearGfxMemory			; Очищаем видеопамять
		push	hl
		call	cliKernel
		pop	hl

;---------------
		push	hl
		ld	hl,sxgWidthMsg
		call	sxgPrint
		pop	hl
;---------------
		inc	hl
		ld	c,(hl)					; Width 0-512
		inc	hl
		ld	b,(hl)

		call	sxgAlignX

;---------------
		push	hl
		push	bc
		push	bc
		pop	hl

		ld	de,sxgWidthMsg0
		ld	a,int2str
		call	cliKernel

		ld	hl,sxgWidthMsg0
		call	sxgPrint

		ld	hl,sxgHeigthMsg
		call	sxgPrint
		pop	bc
		pop	hl
;---------------
		ld	a,(imageMode)				; TODO: ZX Mode(?)
		cp	#01					; 16c
		jr	nz,skipImageDec

		ld	a,#01
		ld	(widthLoop+2),a

		xor	a					; длина/2 = 4 бита на точку
		srl	b
		rr	c
		jr	c,skipImageDec
; 		dec	c
;		inc	c

skipImageDec	
		ld	(imageWidth),bc
		ld	(countWidth),bc

		inc	hl
		ld	c,(hl)					; Height 0-512
		inc	hl
		ld	b,(hl)

		ld	(imageHeight),bc
		ld	(countHeight),bc

		call	sxgAlignY
;---------------
		push	hl
		push	bc
		pop	hl

		ld	de,sxgHeigthMsg0
		ld	a,int2str
		call	cliKernel

		ld	hl,sxgHeigthMsg0
		call	sxgPrint

		ld	hl,sxgScreenMsg
		call	sxgPrint

		ld	hl,sxgLoadingMsg
		call	sxgPrint
		pop	hl
;---------------
		inc	hl
		ld	c,(hl)					; Указатель (смещение) на начало данных палитры
		inc	hl
		ld	b,(hl)

		inc	hl

		push	hl
		add	hl,bc					; Начало данных палитры
gPalNum		ld	b,#01					; Номер экрана для кого грузить палитру
		ld	a,setGfxPalette
		call	cliKernel

		pop	hl

		ld	c,(hl)					; Указатель (смещение) на начало данных bitmap
		inc	hl
		ld	b,(hl)

		inc	hl
		add	hl,bc					; Начало данных bitmap
;---------------
		call	setVBank
		
		ld	de,#0000				; Начало экрана

loadSxgLoop	ld	a,(hl)
		ld	(de),a
		inc	de
		inc	hl

		ld	bc,(countWidth)				
		dec	bc					; Уменьшаем счётчик ширины
		ld	(countWidth),bc
		ld	a,b
		or	c
		jr	nz,nextWidth				; Если счётчик ширины ещё не 0, пропускаем nextWidth


		ld	bc,(imageWidth)
		ld	(countWidth),bc

widthLoop	ld	a,b					; Добиваем линию до 512
		cp	#02
		jr	z,noNeedWidth
 		
 		inc	bc
 		inc	de
		jr	widthLoop

noNeedWidth	ld	bc,(countHeight)
		dec	bc
		ld	(countHeight),bc
		ld	a,b
		or	c
		jr	z,loadSxgStop
;--------
nextWidth	ld	a,d
		cp	#40					; Проверяем, а не заполнили ли мы уже целую банку #4000
		jr	nz,skipIncBank				; Если нет, то пропускаем skipIncBank

		ld	a,(setVBank+1)
		inc	a
		ld	(setVBank+1),a
		call	setVBank
; 		ld	de,#0000
		ld	d,#00

skipIncBank	ld	a,h					; Проверяем, а не закончились ли данные ?
		or	l
		jr	nz,loadSxgLoop				; Если нет, то на новый круг loadSxgLoop

		ld	(sxgStoreDe+1),de

		ld	a,loadNextPart				; Загрузить следующую часть в буфер
		call	cliKernel

		cp	#ff					; конец файла?
		jr	z,loadSxgEnd

sxgStoreDe	ld	de,#0000
		call	setVBank
		ld	hl,sxgBuffer
		jp	loadSxgLoop

loadSxgEnd	ex	af,af'
		cp	eFileEnd
		jr	nz,loadSxgLoop

loadSxgStop	ld	a,restoreWcBank
		call	cliKernel

;---------------------------------------------	
setViewerMode	ld	a,#00
		cp	#01
		jr	nz,loadSxgExit				; если не задан режим вьювера - просто выход
		
		ld	hl,viewerModeMsg
		ld	a,printOkString
		call	cliKernel

		ld	b,50
		halt
		djnz	$-1

vmMode		ld	b,#01
		ld	a,switchGfxMode
		call	cliKernel

viewerModeLoop	halt
		ld	a,getKeyWithShift
		call	cliKernel

		cp	aCurLeft
		jp	z,sxgLeftKey

		cp	aCurRight
		jp	z,sxgRightKey

		cp	aCurUp
		jp	z,sxgUpKey

		cp	aCurDown
		jp	z,sxgDownKey

		cp	aEsc
		jp	z,viewerModeEnd

		jr	viewerModeLoop

viewerModeEnd	ld	a,switchTxtMode
		call	cliKernel

loadSxgExit	ld	a,#00
		cp	#01
		ret	z
		ld	a,printRestore
		jp	cliKernel
;---------------------------------------------
sxgUpKey	ld	a,moveScreenUp
		jr	sxgMoveNow

sxgDownKey	ld	a,moveScreenDown
		jr	sxgMoveNow

sxgLeftKey	ld	a,moveScreenLeft
		jr	sxgMoveNow

sxgRightKey	ld	a,moveScreenRight
		
sxgMoveNow	push	af
		ld	a,(moveStep)
		ex	af,af'
		pop	af
		call	cliKernel
		jp	viewerModeLoop
;---------------------------------------------
setVBank	ld	a,#10					; #10-#1F - страницы из 2го видео буфера
		ex	af,af'
		ld	a,setRamPage0
		jp	cliKernel
;---------------------------------------------
sxgShowInfo	call	sxgLoaderVer				; Вывод информации о программе
		call	sxgLoaderHelp
		jp	loadSxgExit

sxgLoaderVer	ld	hl,sxgVersionMsg			
		ld	a,printAppNameString
		call	cliKernel

		ld	hl,sxgCopyRMsg
		ld	a,printCopyrightString
		call	cliKernel
		ld	a,#01					; Просто выйти если файл не задан
		ld	(sxgFileCheck+1),a
		ret

sxgLoaderHelp	ld	hl,sxgUsageMsg
		ld	a,printString
		call	cliKernel
		ld	a,#01					; Просто выйти если файл не задан
		ld	(sxgFileCheck+1),a
		ret

;---------------------------------------------
sxgViewerMode	ld	a,#01					; Включить режим вьювера после загрузки
		ld	(setViewerMode+1),a
		ld	(sxgFileCheck+1),a
		xor	a					; Обязательно должно быть 0!!!
		ret

;---------------------------------------------
fileNotSet	ld	hl,noFileMsg
		ld	a,printErrorString
		jp	cliKernel

;---------------------------------------------
fileNotFound	ld	a,printFileNotFound
fileNotFound_1	ld	hl,#0000
		jp	cliKernel

;---------------------------------------------
wrongFile	ld	hl,wrongFileMsg
		ld	a,printErrorString
		call	cliKernel
		ld	a,#ff					; error
		ret

;---------------------------------------------
setImageMode	; Неправильный формат -> выход
		push	af
		ex	af,af'
sxgType		ld	b,#01
		ld	a,setGfxColorMode			; на входе в A = цветовой режим: %00-ZX, %01-16c, %10-256c, %11 - txt
		call	cliKernel
		pop	af
		ld	hl,sxgTypeZXMsg
		cp	#00					
		jr	z,setImageMode_0
		ld	hl,sxgType16Msg
		cp	#01
		jr	z,setImageMode_0
		ld	hl,sxgType256Msg
		cp	#02
		jr	z,setImageMode_0
		ld	hl,sxgTypeWrongMsg
		call	setImageMode_0
		jp	wrongFile				; Неправильный формат -> выход

setImageMode_0	call	sxgPrint
		xor	a					; ok
		ret
;---------------------------------------------
sxgSetSpeed	ld	a,getNumberFromParams
		call	cliKernel
		cp	#ff
		jp	z,wrongParams

		ld	a,l
		ld	(moveStep),a
		ld	a,#fe					; Пропустить следующее значение
		ret

;---------------------------------------------
sxgSetScreen	ld	a,getNumberFromParams
		call	cliKernel
		cp	#ff
		jp	z,wrongParams

		ld	a,h
		cp	#00
		jp	nz,wrongParams
		ld	a,l
		cp	#04
		jr	c,sxgSetScreen_0
		jp	wrongParams

sxgSetScreen_0	ld	a,l
		ld	(sxgVMem+1),a
		ld	(sxgOffX+1),a
		ld	(sxgOffY+1),a
		ld	(sxgType+1),a
		ld	(vmMode+1),a
		ld	(gPalNum+1),a
		push	af
		sla	a
		sla	a
		sla	a
		sla	a
		ld	(setVBank+1),a
		pop	af
		push	hl,de
		ld	de,sxgScreenMsg0
		ld	h,#00
		ld	l,a
		ld	a,fourbit2str
		call	cliKernel
		pop	de,hl
		ld	a,#fe					; Пропустить следующее значение
		ret
;---------------------------------------------
sxgAlignX	ld	a,#00
		cp	#00
		ret	z
		ld	a,b
		cp	#00
		jr	z,sxgAlignX_0
		ld	a,c
		cp	#68					; #0168 = 360
		jr	c,sxgAlignX_0
		push	hl,de,bc
		ld	hl,#0000	
		jr	sxgOffX

sxgAlignX_0	push	hl,de,bc
		ld	hl,360
		sbc	hl,bc
		ld	de,2
		ld	a,divide16_16
		call	cliKernel				; bc,hl
		ld	hl,512
		sbc	hl,bc
sxgOffX		ld	b,#01
		ld	a,setScreenOffsetX
		call	cliKernel
		pop	bc,de,hl
		ret
; ---------------------------------------------
sxgAlignY	ld	a,#00
		cp	#00
		ret	z
		ld	a,b
		cp	#00
		jr	z,sxgAlignY_0
		ld	a,c
		cp	#20					; #0120 = 288
		jr	c,sxgAlignY_0
		push	hl,de,bc
		ld	hl,#0000	
		jr	sxgOffY

sxgAlignY_0	push	hl,de,bc
		ld	hl,288
		sbc	hl,bc
		ld	de,2
		ld	a,divide16_16
		call	cliKernel				; bc,hl
		ld	hl,512
		sbc	hl,bc
sxgOffY		ld	b,#01
		ld	a,setScreenOffsetY
		call	cliKernel
		pop	bc,de,hl
		ret
; ---------------------------------------------
sxgSetAlignX	ld	a,#01
		ld	(sxgAlignX+1),a
		xor	a					; Обязательно должно быть 0!!!
		ret

sxgSetAlignY	ld	a,#01
		ld	(sxgAlignY+1),a
		xor	a					; Обязательно должно быть 0!!!
		ret

;---------------------------------------------
wrongParams	ld	hl,wrongParamsMsg
		ld	a,printErrorString
		call	cliKernel
		ret

;---------------------------------------------
sxgPrint	ld	a,#00
		cp	#01
		ret	z
		ld	a,printString
		jp	cliKernel

setSilentMode	ld	a,#01
		ld	(sxgPrint+1),a
		ld	(loadSxgExit+1),a
		xor	a					; Обязательно должно быть 0!!!
		ret
;---------------------------------------------
moveStep	db	#02					; скорость перемещение для рещима вьювера в px

imageMode	db	#00
imageWidth	dw	#0000
imageHeight	dw	#0000

countWidth	dw	#0000
countHeight	dw	#0000

sxgVersionMsg	db	"SXG (Spectrum eXtended Graphics) file loader v0.06",#00
sxgCopyRMsg	db	"2013,2015 ",127," Breeze\\\\Fishbone Crew",#00
		
sxgUsageMsg	db	#0d,15,5,"Usage: loadsxg [switches] filename.sxg",#0d
		db	16,16,"  -vm ",15,15,"\tviewer mode. activate viewer mode after image has loaded",#0d
		db	16,16,"  -sp n",15,15,"\tspeed. set move speed in viewer mode (default 2px)",#0d
		db	16,16,"  -g n",15,15,"\tgraphics screen. select screen to load (default 1)",#0d
		db	16,16,"  -v ",15,15,"\tversion. show application's version and copyrights",#0d
		db	16,16,"  -cx ",15,15,"\talign centers vertically (if width less than 360)",#0d
		db	16,16,"  -cy ",15,15,"\talign centers horizontally (if heigth less than 288)",#0d
		db	16,16,"  -s ",15,15,"\tsilent mode. additional information is not displayed",#0d
 		db	16,16,"  -h ",15,15,"\thelp. show this info"
		db	16,16,#0d,#00

noFileMsg	db	"Error: Incorrect file name.",#0d,#0d,#00
wrongFileMsg	db	"Error: Incorrect file format.",#0d,#0d,#00

viewerModeMsg	db	"Viewer mode. Use ",24,25,26,27," to navigate. Press ",20, " ESC ",20," to exit.",#0d,#0d,#00
wrongParamsMsg	db	"Error: Wrong parametrs.",#0d,#0d,#00

sxgFormatMsg	db	" ",249," Image format: SXG detected!",#0d,#00
sxgVerMsg	db	" ",249," SXG Header Version: ",#00
sxgBgMsg	db	" ",249," BackGround color: ",#00
sxgPackMsg	db	" ",249," Pack Type: ",#00
sxgNumberMsg	db	"--",#0d,#00
sxgTypeMsg	db	" ",249," Image type: ",#00
sxgTypeZXMsg	db	"SCR (6912)",#0d,#00
sxgType16Msg	db	"16 colors",#0d,#00
sxgType256Msg	db	"256 colors",#0d,#00
sxgTypeWrongMsg	db	16,10,"Unknown!",16,16,#0d,#00
sxgWidthMsg	db	" ",249," Image width: ",#00
sxgWidthMsg0	db	"-----px",#0d,#00
sxgHeigthMsg	db	" ",249," Image heigth: ",#00
sxgHeigthMsg0	db	"-----px",#0d,#00
sxgScreenMsg	db	" ",249," Screen selected: "
sxgScreenMsg0	db	"01",#0d,#00
sxgLoadingMsg	db	#0d,"Loading...",#0d,#00
;---------------------------------------------
; Key's table for params
;---------------------------------------------
keyTable
		db	"-s"						; s должно быть выше чем sp
		db	"*"
		dw	setSilentMode

		db	"-h"
		db	"*"
		dw	sxgShowInfo

		db	"-v"
		db	"*"
		dw	sxgLoaderVer

		db	"-vm"
		db	"*"
		dw	sxgViewerMode

		db	"-sp"
		db	"*"
		dw	sxgSetSpeed

		db	"-g"
		db	"*"
		dw	sxgSetScreen

		db	"-cx"
		db	"*"
		dw	sxgSetAlignX

		db	"-cy"
		db	"*"
		dw	sxgSetAlignY

;--- table end marker ---
		db	#00

;---------------------------------------------
appEnd		nop
		org	#e000
sxgBuffer	nop


		SAVEBIN "install/bin/loadsxg", appStart, appEnd-appStart

		DISPLAY "loadSxgLoop",/A,loadSxgLoop
		;DISPLAY "skipImageDec",/A,skipImageDec
		;DISPLAY "skipIncBank",/A,skipIncBank
		