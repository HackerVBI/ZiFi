#include <windows.h>

HANDLE port;
DCB dcb;
COMMTIMEOUTS touts;



//init uart
int uart_init(char *comport)
{
  port = CreateFile(comport, GENERIC_READ | GENERIC_WRITE,
      FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
  if (port==INVALID_HANDLE_VALUE) return -1;

  if (GetCommState(port, &dcb))
  {
     dcb.BaudRate = CBR_115200;
     dcb.ByteSize = 8; dcb.Parity = 0; dcb.StopBits = 0;
     dcb.fAbortOnError = 0;
     SetCommState(port, &dcb);
  }

  if (GetCommTimeouts(port, &touts))
  {
     touts.ReadIntervalTimeout = MAXDWORD;
     touts.ReadTotalTimeoutMultiplier = MAXDWORD;
     touts.ReadTotalTimeoutConstant = MAXDWORD;
     touts.WriteTotalTimeoutMultiplier = MAXDWORD;
     touts.WriteTotalTimeoutConstant = MAXDWORD;

     SetCommTimeouts(port, &touts);
  }

//  PurgeComm(port, PURGE_RXCLEAR+PURGE_TXCLEAR);
  return 0;
}


//read byte (can use int)
void uart_read(char *buf, int len)
{
  unsigned long nread=0,s;

  for(s=0; s<len;)
  {
    ReadFile(port, &buf[s], len, &nread, NULL);
    s+=nread;
  }
}


//write byte 2 usart
void uart_write(char *buf, int len)
{
  unsigned long nread=0;

  WriteFile(port, buf, len, &nread, NULL);
}




