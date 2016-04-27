#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "ic_main.h"
#include "ic_comm.h"
#include "ic_cmds.h"
#include "log.h"

int debug=0;

void usage(void)
{
#ifdef __WIN32
  printf("Usage: ic.exe COMx [-b baudrate] [-q] [-q]\n\n");
#else
  printf("Usage: ic /dev/ttyUSBx [-b baudrate] [-q] [-q]\n\n");
#endif
  printf("Supported baud rates: 115200 (default), 57600, 38400,\n");
  printf("                      19200, 9600, 4800, 2400, 1200\n");
  printf("Use single -q for quiet mode,\n");
  printf("double -q for complete silence.\n");
}


int main(int argc, char *argv[])
{
  char *sname=NULL,*p;
  int i, baud=115200, q=0;

  for (i = 1; i < argc; i++)
  {
    p = argv[i];
    if (*p == '-')
    {
      if (strcmp(p, "-b") == 0) baud = atoi(argv[++i]);
      else if (strcmp(p, "-q") == 0) q++;
      else if (strcmp(p, "-d") == 0) debug=1;
    }
    else if (!sname) sname = p;
         else
         {
           usage();
           return -1;
         }
  }

  if(!sname)
  {
    usage();
    return -1;
  }

  loginit(q);

  if(init(sname, baud) < 0)
  {
    logerr("Init error.");
    return -2;
  }

  if(q<2)
  {
    printf("ZX-Spectrum Internet Controller Emulator v%s.%s.\n",VER_MAJOR,VER_MINOR);
    printf("Serial device used: %s at %d baud.\n", sname, baud);
  }

  process();
  return 0;
}

