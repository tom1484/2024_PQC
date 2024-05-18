#include <stdio.h>

#include "mult256.h"

int32_t r0[8] = {0xFF000001, 0x000FF002, 0x00000003, 0x00000004,
                 0x00000005, 0x00000006, 0x00000007, 0x00000008};
int32_t r1[8] = {0xFF000002, 0x000FF003, 0x00000004, 0x00000005,
                 0x00000006, 0x00000007, 0x00000008, 0x00000009};
int32_t r2[8] = {0, 0, 0, 0, 0, 0, 0, 0};
int32_t r3[8] = {0, 0, 0, 0, 0, 0, 0, 0};
int a = 0;

int main() {
  mult256(r0, r1, r2, r3);

  for (int i = 0; i < 8; i++) {
    printf("r2[%d] = %08x\n", i, r2[i]);
  }
  printf("\n");

  for (int i = 0; i < 8; i++) {
    printf("r3[%d] = %08x\n", i, r3[i]);
  }
  printf("\n");

  return 0;
}
