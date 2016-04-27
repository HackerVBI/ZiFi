#include <windows.h>
#include <stdio.h>

HANDLE port;
DCB dcb;
COMMTIMEOUTS touts;
extern int debug;

#define BAUD_ERROR -1U


static DWORD get_baud(int baud)
{
  switch(baud)
  {
    case 115200: return CBR_115200;
    case 57600:  return CBR_57600;
    case 38400:  return CBR_38400;
    case 19200:  return CBR_19200;
    case 9600:   return CBR_9600;
    case 4800:   return CBR_4800;
    case 2400:   return CBR_2400;
    case 1200:   return CBR_1200;
    default:     return BAUD_ERROR;
  }
}





//init uart
int uart_init(char *sname, int baud)
{
  char buf[16], *p;
  DWORD CBR;

  //fix COMx name to \\.\COMx
  if(strncasecmp(sname,"com",3)==0 && strlen(sname)<7)
  {
    sprintf(buf,"\\\\.\\%s",sname);
    p=buf;
  }
  else
  {
    p=sname;
  }

  //check/get baud rate
  CBR = get_baud(baud);
  if(CBR==BAUD_ERROR) return -1;

  //open serial line
  port = CreateFile(p, GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
  if (port==INVALID_HANDLE_VALUE) return -1;

  //set config
  if (GetCommState(port, &dcb))
  {
     dcb.BaudRate = CBR; //CBR_57600; //CBR_115200;
     dcb.ByteSize = 8; dcb.Parity = 0; dcb.StopBits = 0;
     dcb.fAbortOnError = 0;
     SetCommState(port, &dcb);
  }

  //set timeouts
  if (GetCommTimeouts(port, &touts))
  {
     touts.ReadIntervalTimeout = MAXDWORD;
     touts.ReadTotalTimeoutMultiplier = MAXDWORD;
     touts.ReadTotalTimeoutConstant = MAXDWORD;
     touts.WriteTotalTimeoutMultiplier = MAXDWORD;
     touts.WriteTotalTimeoutConstant = MAXDWORD;

     SetCommTimeouts(port, &touts);
  }

  PurgeComm(port, PURGE_RXCLEAR+PURGE_TXCLEAR);
  return 0;
}


//read bytes
void uart_read(char *buf, int len)
{
  unsigned long nread=0,s;

  for(s=0; s<len;)
  {
    ReadFile(port, &buf[s], len-s, &nread, NULL);
    s+=nread;
  }
  if(debug){printf("read: ");for(s=0;s<len;s++) printf("%02x ",(unsigned char)buf[s]); printf("\n");}
}


//write bytes
void uart_write(char *buf, int len)
{
  unsigned long nread=0,s;

  if(debug){printf("write: ");for(s=0;s<len;s++) printf("%02x ",(unsigned char)buf[s]); printf("\n");}
  WriteFile(port, buf, len, &nread, NULL);
}

