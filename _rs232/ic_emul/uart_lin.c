#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <termios.h>
#include <stdio.h>
#include <strings.h>
#include <unistd.h>

#include "uart.h"

#define BAUD_ERROR -1U
int fd;
extern int debug;


static tcflag_t get_baud(int baud)
{
  switch(baud)
  {
    case 115200: return B115200;
    case 57600:  return B57600;
    case 38400:  return B38400;
    case 19200:  return B19200;
    case 9600:   return B9600;
    case 4800:   return B4800;
    case 2400:   return B2400;
    case 1200:   return B1200;
    default:     return BAUD_ERROR;
  }
}


//init uart
int uart_init(char *sname, int baud)
{
  struct termios /*otio,*/ ntio;
  tcflag_t BAUD;

  //check/get baud rate
  BAUD = get_baud(baud);
  if(BAUD==BAUD_ERROR) return -1;

  //open tty
  fd = open(sname, O_RDWR | O_NOCTTY);
  if(fd<0) return -1;

  //save current port settings
  //tcgetattr(fd,&otio);

  //set config
  bzero(&ntio, sizeof(ntio));
  ntio.c_cflag = BAUD |     //baud rate
                 CS8 |      //8n1
                 CLOCAL |   //local connection, no modem control
                 CREAD;     //enable receiving characters
  ntio.c_iflag = IGNPAR;    //ignore bytes with parity errors
  ntio.c_oflag = 0;         //raw output
  ntio.c_lflag = 0;         //non-canonical input

  ntio.c_cc[VMIN] = 1;      //wait for 1 byte minimum

  //flush and apply new settings
  tcflush(fd, TCIFLUSH);
  tcsetattr(fd,TCSANOW,&ntio);
  return 0;
}


//read bytes
void uart_read(char *buf, int len)
{
  unsigned long s=0;

  while(s<len)
  {
    s+=read(fd,&buf[s],len-s);
  }
  if(debug){printf("read: ");for(s=0;s<len;s++) printf("%02x ",(unsigned char)buf[s]); printf("\n");}
}

//write bytes
void uart_write(char *buf, int len)
{
  int s;

  if(debug){printf("write: ");for(s=0;s<len;s++) printf("%02x ",(unsigned char)buf[s]); printf("\n");}
  write(fd,buf,len);
}



