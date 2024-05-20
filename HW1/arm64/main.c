#include <stdio.h>

#include "mult256.h"

char input0[100] = "";
char input1[100] = "";

int r0[8] = {0};
int r1[8] = {0};
int r2[8] = {0};
int r3[8] = {0};

void print256(int *r) {
  for (int i = 0; i < 8; i++) {
    printf("%08X", r[7 - i]);
  }
  printf("\n");
}

int read_input() {
  // Input hex strings
  scanf("%s\n", input0);
  scanf("%s\n", input1);

  // Convert hex strings to int arrays
  for (int i = 0; i < 8; i++) {
    sscanf(input0 + 8 * (7 - i), "%8X", &r0[i]);
    sscanf(input1 + 8 * (7 - i), "%8X", &r1[i]);
  }

  return 0;
}

int main() {
  while (!feof(stdin)) {
    read_input();
    mult256(r0, r1, r2, r3);

    print256(r3); // upper 256 bits
    print256(r2); // lower 256 bits
  }

  return 0;
}
