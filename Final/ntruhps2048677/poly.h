#ifndef POLY_H
#define POLY_H

#include "params.h"

#include <stddef.h>
#include <stdint.h>

#define POLY_N 1024

typedef struct {
    uint16_t coeffs[POLY_N];
} poly;


void poly_Rq_mul_small(poly *r, const poly *a, const poly *b);

#endif
