
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stddef.h>
#include <assert.h>

#include <arm_neon.h>

#include "params.h"
#include "poly.h"
#include "hal.h"

#define ITERATIONS 10000


static void schoolbook_core(uint16_t des[NTRU_N], const uint16_t src1[NTRU_N], const uint16_t src2[NTRU_N]){

    uint16_t tmp[NTRU_N * 2]; 

    for(size_t i = 0; i < NTRU_N * 2; i++){
        tmp[i] = 0;
    }   
    
    for(size_t i = 0; i < NTRU_N; i++){
        for(size_t j = 0; j < NTRU_N; j++){
            tmp[i + j] += src1[i] * src2[j]; 
        }
    }

    for(size_t i = 0; i < NTRU_N; i++){
        des[i] = tmp[i];
    }

    for(size_t i = NTRU_N; i < NTRU_N * 2; i++){
        des[i - NTRU_N] += tmp[i];
    }

}

static void schoolbook(poly *des, const poly *src1, const poly *src2){
    schoolbook_core(des->coeffs, (const uint16_t*)src1->coeffs, (const uint16_t*)src2->coeffs);
}


int main(void){

    poly ref, src1, src2;
    poly res;

    for(size_t i = 0; i < ITERATIONS; i++){

        for(size_t j = 0; j < NTRU_N; j++){
            src1.coeffs[j] = rand() % NTRU_Q;
            src2.coeffs[j] = rand() % 3;
            if(src2.coeffs[j] == 2){
                src2.coeffs[j] = NTRU_Q - 1;
            }
        }
        for(size_t j = NTRU_N; j < POLY_N; j++){
            src1.coeffs[j] = 0;
            src2.coeffs[j] = 0;
        }

        schoolbook(&ref, &src1, &src2);
        poly_Rq_mul_small(&res, &src1, &src2);

        for(size_t j = 0; j < NTRU_N; j++){
            assert(MODQ(ref.coeffs[j]) == MODQ(res.coeffs[j]));
        }

    }
    printf("poly_Rq_mul_small passed!\n");

}


