#include <stdio.h>

#include "ic_comm.h"
#include "ic_cmds.h"
#include "log.h"





int main(int argc, char *argv[])
{
  if(argc<2)
  {
    log_("Usage: ic_emul.exe COMx");
    return -1;
  }

  if(init(argv[1]) < 0)
  {
    logerr("Init error.");
    return -2;
  }

  printf("ZX-Spectrum Internet Controller Emulator v0.1\n");
  process();

  return 0;
}

