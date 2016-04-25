/*Understand, Correct, Improve          ___
 ________/| _________________/\__/\____/  /_____
 \  ____/ |/   __/  /  / __ /  \/  \  \  /   __/
 |   __/  /\__   \    /  __ \      /     \  _/ \
 |___\ \__\____  //__/\_____/\    /__/\  /_____/
 `-------------\/------breeze-\  /crew-\/------'
			       			   \/
  BMP to SXG (Speccy eXtended Graphics) [PentEvo 256]
  ----------------------------------------------------------
  Written by breeze \ fishbone crew | http://fishbone.untergrund.net/
  breeze@tut.by
  18.02.2015
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

//---------------------------------------------------------------------------------------------
void printBits(char number){
	char *bitsStr = "00000000\0";
	for (int pos=8; pos>0; pos--) {
		if(number > 0){
			bitsStr[pos-1] = '0' + (number%2);
			number = number/2;
		} else {
			bitsStr[pos-1] = '0';
		}
	}
	printf(bitsStr);
}

unsigned int fileLength(FILE *f) {
	int pos;
	int end;

	pos = ftell (f);
	fseek (f, 0, SEEK_END);
	end = ftell (f);
	fseek (f, pos, SEEK_SET);

	return end;
}

void printStrint (char *str) {
	for (int i=0; str[i] != '\0'; i++){
		printf ("%c", str[i]);
	}
}

bool testHex (char testChar) {
	bool valid = false;

	if ((testChar > 0x2F && testChar < 0x39) || (testChar > 0x40 && testChar < 0x47)) {
		valid = true;
	}
	return valid;
}

//---------------------------------------------------------------------------------------------
int main (int argc, char *argv[]) {
	char *filename = NULL;
	bool debugMode = false;
	bool enableShim = true;

	if ((argc > 1) && (argv[1][0] != '-')) {
		filename = argv[1];
		++argv;
		--argc;
	}

	while ((argc > 1) && (argv[1][0] == '-' && argv[1][1] == '-')) {
		//printf("arg %d = param %s\n", argc, argv[1]);
		if (strcmp (argv[1], "--debug") == 0) {
			debugMode = true;
		} else if (strcmp (argv[1], "--64") == 0) {
			enableShim = false;
		}
		++argv;
		--argc;
	}
	
	// \033[22;30m - black
	// \033[22;31m - red
	// \033[22;32m - green
	// \033[22;33m - brown
	// \033[22;34m - blue
	// \033[22;35m - magenta
	// \033[22;36m - cyan
	// \033[22;37m - gray
	// \033[01;30m - dark gray
	// \033[01;31m - light red
	// \033[01;32m - light green
	// \033[01;33m - yellow
	// \033[01;34m - light blue
	// \033[01;35m - light magenta
	// \033[01;36m - light cyan
	// \033[01;37m - white

	printf("\nBMP to SXG (Speccy eXtended Graphics) v0.4 (alpha)   18 Feb 2015\n");
	printf("-----------------------------------------------------------------------------------\n");
	printf("Written by breeze\\fishbone crew | fishbone@speccy.su | http://fishbone.untergrund.net/\n");
	printf("\n");

	if (filename == NULL) {
		printf("Usage:     bmp2sxg <filename> [commands]\n");
		printf("Commands:\n");
	  	printf("  --debug   enable output debug information (default disabled)\n");
	  	printf("  --64      cut palette to atm 64 colors limit (default disabled)\n");
	} else {

		printf("Debug: ");
		if (debugMode) {
		    printf("Enabled\n");
		} else {
		    printf("Disabled\n");
		}
		printf("Full colors: ");
		if (enableShim) {
		    printf("Enabled\n");
		} else {
		    printf("Disabled\n");
		}
		printf("Work file: %s ", filename);

		FILE *readfile = fopen(filename, "rb");

		if (readfile != NULL) {
			unsigned int filelen = fileLength(readfile);

			if (filelen > 0) {
				printf("(%i bytes)\n", filelen);
				void *fileContent = malloc( filelen + 1 );
				fread(fileContent, filelen, 1, readfile);
				fclose(readfile);
				memcpy ((void *)((unsigned int)fileContent + filelen), "\0", 1);
				printf ("File analizing... ");

				unsigned char *bmpData = (unsigned char *)fileContent;
				unsigned char *beginData = (unsigned char *)fileContent;

				if (*(bmpData) == 'B' && *(bmpData+1) == 'M')  {
					bmpData += 2;

					printf("BMP format detected!\n");

					unsigned long bmpSize = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					bmpData += 4;       // reserved 4 bytes
					unsigned long imageStart = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long headerSize = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long bmpWidth = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long bmpHeigth = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned short bmpLayers = *(bmpData) + (*(bmpData+1)*256);
					bmpData += 2;
					unsigned short bmpBits = *(bmpData) + (*(bmpData+1)*256);
					bmpData += 2;
					unsigned long bmpCompressType = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long bmpCompressSize = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long bmpHorizontal = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long bmpVertical = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long bmpColors = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;
					unsigned long bmpColorsActive = (*(bmpData) + (*(bmpData+1)*256)) + (*(bmpData+2) + (*(bmpData+3)*256))*256;
					bmpData += 4;

					printf("\nBMP header:\n");
					printf("---------------------------------\n");
					printf ("  file size: %d bytes\n", bmpSize);
					printf ("  image width: %d px\n", bmpWidth);
					printf ("  image heigth: %d px\n", bmpHeigth);
					printf ("  image planes: %d\n", bmpLayers);
					printf ("  bits/pixel: %d\n", bmpBits);

					//printf ("  compress type: %d (0-NO, 1-RLE8, 2 - RLE4)\n", bmpCompressType);
					printf ("  compress type: %d ", bmpCompressType);
					switch (bmpCompressType) {
						case 0:
							printf ("(none)");
							break;
						case 1:
							printf ("(RLE 8-bit/pixel)");
							break;
						case 2:
							printf ("(RLE 4-bit/pixel)");
							break;
						case 3:
							printf ("(Bit field or Huffman 1D compression for BITMAPCOREHEADER2)");
							break;
						case 4:
							printf ("(JPEG or RLE-24 compression for BITMAPCOREHEADER2)");
							break;
						case 5:
							printf ("(PNG)");
							break;
						case 6:
							printf ("(Bit field)");
							break;
						default:
							printf ("(unknown)");
					}
					printf ("\n");
					printf ("  image size: %d bytes\n", bmpCompressSize);
					printf ("  x pixels per meter: %d\n", bmpHorizontal);
					printf ("  y pixels per meter: %d\n", bmpVertical);
					printf ("  colors in color table: %d\n", bmpColors);
					printf ("  important color count: %d\n\n", bmpColorsActive);

					if (bmpCompressType == 0) {
						printf("BMP palette:\n");
						printf("---------------------------------\n");

						unsigned char realColorz = bmpColors;

						if ( realColorz == 0 ) {
						 	realColorz = bmpBits * bmpBits;
						}

						if (realColorz > 0) {
							unsigned char colorz[realColorz*2];
							printf ("BMP use calculated colors: %d\n\n", realColorz);
							if (debugMode) {
								printf ("           No #      R   G   B        R   G   B        pentevo    xRRrrrGG gggBBbbb\n");
							}
							int index = 0;
							for (int i = 0; i<realColorz; i++) {
								if (debugMode) {
									printf("BMP color %3d[#%02X] ",i,i);
								}

								unsigned char b = *(bmpData);
								bmpData++;
								unsigned char g = *(bmpData);
								bmpData++;
								unsigned char r = *(bmpData);
								bmpData++;
								unsigned char x = *(bmpData); // reserved
								bmpData++;

								if (debugMode) {
									printf("[#%02X,#%02X,#%02X] -> ",r,g,b);
								}

								unsigned char colorCodeL = 0;
								unsigned char colorCodeH = 0;

								r = (r/10.6 + 0.5);
								g = (g/10.6 + 0.5);
								b = (b/10.6 + 0.5);

								if (enableShim) {
									colorCodeL = (b & 31) | ((g & 7)<<5);
									colorCodeH = ((r & 31)<<2) | ((g & 31)>>3);
								} else {
									colorCodeL = (b & 24);
									colorCodeH = ((r & 24)<<2) | ((g & 24)>>3);
								}

								if (debugMode) {
									printf("%3d,%3d,%3d ",r,g,b);
									printf("-> %3d,%3d[#%02X%02X] ", colorCodeH, colorCodeL, colorCodeH, colorCodeL);
									printBits(colorCodeH);
									printf(" ");
									printBits(colorCodeL);
									printf("\n");
								}

								colorz[index] = colorCodeL;
								index++;
								colorz[index] = colorCodeH;
								index++;
							}

							printf("\nBMP Bitmap data...\n");
							printf("---------------------------------\n");

							// bmpBits 1 - bitmap is monochrome
							// bmpBits 4 - bitmap has a maximum of 16 colors
							// bmpBits 8 - bitmap has a maximum of 256 colors
							// bmpBits 16 - bitmap has a maximum of 65536 colors
							// bmpBits 32 - bitmap has a maximum of 16777216 colors
							
							printf("Bitmap bits - %d \n", bmpBits);

							if (bmpBits == 4 || bmpBits == 8) {
								unsigned long dataLen = ( bmpWidth * bmpHeigth );
								if ( dataLen > 0 ) {
									if (bmpBits == 4) {
										dataLen = dataLen/2;
									}

									printf("Bitmap data length - %d bytes\n", dataLen);

									unsigned char *bmpImageData=(unsigned char *)(beginData+imageStart);
									unsigned char *memImageData = (unsigned char *)malloc(dataLen);
									unsigned char *workImageData = (unsigned char *)(memImageData);
									unsigned long spriteWidth = bmpWidth;

									if (bmpBits == 4) {
										spriteWidth = bmpWidth / 2;
									}

									for (int y = bmpHeigth - 1; y >= 0; y-- ) {
										for (int x = 0; x < spriteWidth; x++){
											unsigned char colorPixel = *(bmpImageData + x + ( y * spriteWidth ));
											*workImageData = colorPixel;
											workImageData++;
											if (debugMode) {
												printf("#%02X,",colorPixel);
											}
										}
										if (debugMode) {
											printf("\n");
										}
									}
									
									unsigned char colorzFinal[realColorz*2];
									for (int i=0; i<realColorz*2; i++) {
										colorzFinal[i] = colorz[i];
									}

									// +#0000 #03 "SXG" - 3 байта сигнатура, что это формат файла
									// +#0003 #01 1 байт формат изображения (1 - 16ц, 2 - 256ц)
									// +#0004 #02 2 байта ширина изображения
									// +#0006 #02 2 байта высота изображения
									// (что бы можно было добавить ещё параметры)
									// +#0008 #02 смещение от текущего адреса до начала данных палитры 
									// +#000a #02 смещение от текущего адреса до начала данных битмап
									// Начало данных палитры
									// +#000с #0200 512 байт палитра
									// Начало данных битмап
									// +#020с #xxxx данные битмап

									char *saveFileName = strtok(filename, ".");
									saveFileName = strcat(saveFileName,".sxg");
									FILE *writeSxgFile = fopen(saveFileName, "wb");
									if (writeSxgFile != NULL) {
										unsigned char *sxgId = "\x7FSXG";
										fwrite(sxgId, 1, 4, writeSxgFile);

										unsigned char sxgType = 1;
										if (bmpBits > 4) {
											sxgType = 2;
										}
										fwrite(&sxgType, 1, 1, writeSxgFile);

										short int sxgWidth = (short int)bmpWidth;
										short int sxgHeigth = (short int)bmpHeigth;

										fwrite(&bmpWidth, 1, sizeof(short int), writeSxgFile);
										fwrite(&bmpHeigth, 1, sizeof(short int), writeSxgFile);

										short int palStart = 2;
										fwrite(&palStart, 1, sizeof(short int), writeSxgFile);
										
										short int palSize = realColorz*2;
										fwrite(&palSize, 1, sizeof(short int), writeSxgFile);

										fwrite(colorzFinal, 1, palSize, writeSxgFile);
										
										workImageData = memImageData;
										unsigned long writeLen = dataLen;

										fwrite(workImageData, 1, writeLen, writeSxgFile);

									} else {
										printf ("Error: Can't write file: %s", saveFileName);
									}
									free (memImageData);
								} else {
									printf("Error: Wrong bitmap legth!\n");
									return 1;
								}
							} else {
								printf("Error: support only 16 & 256 colors bmp!\n");
								return 1;
							}

						} else {
							printf("Error: Wrong BMP palette.\n");
							return 1;
						}
					} else {
						printf("Error: Compressed file not supported yet.\n");
						return 1;
					}
				} else {
					printf("Error: Wrong format of file - %s\n", filename);
					return 1;
				}
				free (fileContent);
			} else {
				printf ("Error: Wrong size of file - %s\n", filename);
				return 1;
			}
		} else {
			printf ("Error: Can't opening file -  %s\n", filename);
			return 1;
		}
	}
	return 0;
}
