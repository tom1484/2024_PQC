#include "poly.h"
#include <arm_neon.h>
#include "hal.h"

#define PAD32(X) ((((X) + 31)/32)*32)
#define L PAD32(NTRU_N)
#define M (L/4)
#define K (L/16)
#define Km8 ((K >> 3) << 3)
#define Mm8 ((M >> 3) << 3)

/* Polynomial multiplication using     */
/* Toom-4 and two layers of Karatsuba. */

static void toom4_k2x2_mul(uint16_t ab[2 * L], const uint16_t a[L], const uint16_t b[L]);

static void toom4_k2x2_eval_0(uint16_t r[9 * K], const uint16_t a[L]);
static void toom4_k2x2_eval_p1(uint16_t r[9 * K], const uint16_t a[L]);
static void toom4_k2x2_eval_m1(uint16_t r[9 * K], const uint16_t a[L]);
static void toom4_k2x2_eval_p2(uint16_t r[9 * K], const uint16_t a[L]);
static void toom4_k2x2_eval_m2(uint16_t r[9 * K], const uint16_t a[L]);
static void toom4_k2x2_eval_p3(uint16_t r[9 * K], const uint16_t a[L]);
static void toom4_k2x2_eval_inf(uint16_t r[9 * K], const uint16_t a[L]);
static inline void k2x2_eval(uint16_t r[9 * K]);

static void toom4_k2x2_basemul(uint16_t r[18 * K], const uint16_t a[9 * K], const uint16_t b[9 * K]);
static inline void schoolbook_KxK(uint16_t r[2 * K], const uint16_t a[K], const uint16_t b[K]);

static void toom4_k2x2_interpolate(uint16_t r[2 * L], const uint16_t a[63 * 2 * K]);
static inline void k2x2_interpolate(uint16_t r[2 * M], const uint16_t a[18 * K]);


static const int16x8_t const1_vec = {1, 1, 1, 1, 1, 1, 1, 1};
static const int16x8_t const2_vec = {2, 2, 2, 2, 2, 2, 2, 2};
static const int16x8_t const3_vec = {3, 3, 3, 3, 3, 3, 3, 3};
static const uint16x8_t constu3_vec = {3, 3, 3, 3, 3, 3, 3, 3};
static const uint16x8_t constu9_vec = {9, 9, 9, 9, 9, 9, 9, 9};
static const uint16x8_t constu27_vec = {27, 27, 27, 27, 27, 27, 27, 27};

void poly_Rq_mul_small(poly *r, const poly *a, const poly *b) {
    size_t i;
    uint16_t ab[2 * L];

    for (i = 0; i < NTRU_N; i++) {
        ab[i] = a->coeffs[i];
        ab[L + i] = b->coeffs[i];
    }
    for (i = NTRU_N; i < L; i++) {
        ab[i] = 0;
        ab[L + i] = 0;
    }

    toom4_k2x2_mul(ab, ab, ab + L);

    for (i = 0; i < NTRU_N; i++) {
        r->coeffs[i] = ab[i] + ab[NTRU_N + i];
    }
}

static void toom4_k2x2_mul(uint16_t ab[2 * L], const uint16_t a[L], const uint16_t b[L]) {
    uint16_t tmpA[9 * K];
    uint16_t tmpB[9 * K];
    uint16_t eC[63 * 2 * K];

    toom4_k2x2_eval_0(tmpA, a);
    toom4_k2x2_eval_0(tmpB, b);
    toom4_k2x2_basemul(eC + 0 * 9 * 2 * K, tmpA, tmpB);

    toom4_k2x2_eval_p1(tmpA, a);
    toom4_k2x2_eval_p1(tmpB, b);
    toom4_k2x2_basemul(eC + 1 * 9 * 2 * K, tmpA, tmpB);

    toom4_k2x2_eval_m1(tmpA, a);
    toom4_k2x2_eval_m1(tmpB, b);
    toom4_k2x2_basemul(eC + 2 * 9 * 2 * K, tmpA, tmpB);

    toom4_k2x2_eval_p2(tmpA, a);
    toom4_k2x2_eval_p2(tmpB, b);
    toom4_k2x2_basemul(eC + 3 * 9 * 2 * K, tmpA, tmpB);

    toom4_k2x2_eval_m2(tmpA, a);
    toom4_k2x2_eval_m2(tmpB, b);
    toom4_k2x2_basemul(eC + 4 * 9 * 2 * K, tmpA, tmpB);

    toom4_k2x2_eval_p3(tmpA, a);
    toom4_k2x2_eval_p3(tmpB, b);
    toom4_k2x2_basemul(eC + 5 * 9 * 2 * K, tmpA, tmpB);

    toom4_k2x2_eval_inf(tmpA, a);
    toom4_k2x2_eval_inf(tmpB, b);
    toom4_k2x2_basemul(eC + 6 * 9 * 2 * K, tmpA, tmpB);

    toom4_k2x2_interpolate(ab, eC);
}

static inline void toom4_k2x2_eval_0(uint16_t r[9 * K], const uint16_t a[L]) {
    for (size_t i = 0; i < M; i += 8) {
      vst1q_u16(r + i, vld1q_u16(a + i));
    }
    k2x2_eval(r);
}

static inline void toom4_k2x2_eval_p1(uint16_t r[9 * K], const uint16_t a[L]) {
    uint16x8_t a0_vec, a1_vec, a2_vec, a3_vec, r_vec;
    for (size_t i = 0; i < M; i += 8) {
      a0_vec = vld1q_u16(a + 0 * M + i);
      a1_vec = vld1q_u16(a + 1 * M + i);
      a2_vec = vld1q_u16(a + 2 * M + i);
      a3_vec = vld1q_u16(a + 3 * M + i);
      r_vec = vaddq_u16(a0_vec, a1_vec);
      r_vec = vaddq_u16(r_vec, a2_vec);
      r_vec = vaddq_u16(r_vec, a3_vec);
      vst1q_u16(r + i, r_vec);
    }
    k2x2_eval(r);
}

static inline void toom4_k2x2_eval_m1(uint16_t r[9 * K], const uint16_t a[L]) {
    uint16x8_t a0_vec, a1_vec, a2_vec, a3_vec, r_vec;
    for (size_t i = 0; i < M; i += 8) {
      a0_vec = vld1q_u16(a + 0 * M + i);
      a1_vec = vld1q_u16(a + 1 * M + i);
      a2_vec = vld1q_u16(a + 2 * M + i);
      a3_vec = vld1q_u16(a + 3 * M + i);
      r_vec = vsubq_u16(a0_vec, a1_vec);
      r_vec = vaddq_u16(r_vec, a2_vec);
      r_vec = vsubq_u16(r_vec, a3_vec);
      vst1q_u16(r + i, r_vec);
    }
    k2x2_eval(r);
}

static inline void toom4_k2x2_eval_p2(uint16_t r[9 * K], const uint16_t a[L]) {
    uint16x8_t a0_vec, a1_vec, a2_vec, a3_vec, r_vec;
    for (size_t i = 0; i < M; i += 8) {
      a0_vec = vld1q_u16(a + 0 * M + i);
      a1_vec = vshlq_u16(vld1q_u16(a + 1 * M + i), const1_vec);
      a2_vec = vshlq_u16(vld1q_u16(a + 2 * M + i), const2_vec);
      a3_vec = vshlq_u16(vld1q_u16(a + 3 * M + i), const3_vec);
      r_vec = vaddq_u16(a0_vec, a1_vec);
      r_vec = vaddq_u16(r_vec, a2_vec);
      r_vec = vaddq_u16(r_vec, a3_vec);
      vst1q_u16(r + i, r_vec);
    }
    k2x2_eval(r);
}

static inline void toom4_k2x2_eval_m2(uint16_t r[9 * K], const uint16_t a[L]) {
    uint16x8_t a0_vec, a1_vec, a2_vec, a3_vec, r_vec;
    for (size_t i = 0; i < M; i += 8) {
      a0_vec = vld1q_u16(a + 0 * M + i);
      a1_vec = vshlq_u16(vld1q_u16(a + 1 * M + i), const1_vec);
      a2_vec = vshlq_u16(vld1q_u16(a + 2 * M + i), const2_vec);
      a3_vec = vshlq_u16(vld1q_u16(a + 3 * M + i), const3_vec);
      r_vec = vsubq_u16(a0_vec, a1_vec);
      r_vec = vaddq_u16(r_vec, a2_vec);
      r_vec = vsubq_u16(r_vec, a3_vec);
      vst1q_u16(r + i, r_vec);
    }
    k2x2_eval(r);
}

static inline void toom4_k2x2_eval_p3(uint16_t r[9 * K], const uint16_t a[L]) {
    uint16x8_t a0_vec, a1_vec, a2_vec, a3_vec, r_vec;
    for (size_t i = 0; i < M; i += 8) {
      a0_vec = vld1q_u16(a + 0 * M + i);
      a1_vec = vld1q_u16(a + 1 * M + i);
      a2_vec = vld1q_u16(a + 2 * M + i);
      a3_vec = vld1q_u16(a + 3 * M + i);
      r_vec = vmlaq_u16(a0_vec, a1_vec, constu3_vec);
      r_vec = vmlaq_u16(r_vec, a2_vec, constu9_vec);
      r_vec = vmlaq_u16(r_vec, a3_vec, constu27_vec);
      vst1q_u16(r + i, r_vec);
    }
    k2x2_eval(r);
}

static inline void toom4_k2x2_eval_inf(uint16_t r[9 * K], const uint16_t a[L]) {
    for (size_t i = 0; i < M; i += 8) {
      vst1q_u16(r + i, vld1q_u16(a + 3 * M + i));
    }
    k2x2_eval(r);
}

static inline void k2x2_eval(uint16_t r[9 * K]) {
    /* Input:  e + f.Y + g.Y^2 + h.Y^3                              */
    /* Output: [ e | f | g | h | e+f | f+h | g+e | h+g | e+f+g+h ]  */

    size_t i;
    for (i = 0; i < 4 * K; i++) {
        r[4 * K + i] = r[i];
    }
    for (i = 0; i < K; i++) {
        r[4 * K + i] += r[1 * K + i];
        r[5 * K + i] += r[3 * K + i];
        r[6 * K + i] += r[0 * K + i];
        r[7 * K + i] += r[2 * K + i];
        r[8 * K + i] = r[5 * K + i];
        r[8 * K + i] += r[6 * K + i];
    }
}

static void toom4_k2x2_basemul(uint16_t r[18 * K], const uint16_t a[9 * K], const uint16_t b[9 * K]) {
    schoolbook_KxK(r + 0 * 2 * K, a + 0 * K, b + 0 * K);
    schoolbook_KxK(r + 1 * 2 * K, a + 1 * K, b + 1 * K);
    schoolbook_KxK(r + 2 * 2 * K, a + 2 * K, b + 2 * K);
    schoolbook_KxK(r + 3 * 2 * K, a + 3 * K, b + 3 * K);
    schoolbook_KxK(r + 4 * 2 * K, a + 4 * K, b + 4 * K);
    schoolbook_KxK(r + 5 * 2 * K, a + 5 * K, b + 5 * K);
    schoolbook_KxK(r + 6 * 2 * K, a + 6 * K, b + 6 * K);
    schoolbook_KxK(r + 7 * 2 * K, a + 7 * K, b + 7 * K);
    schoolbook_KxK(r + 8 * 2 * K, a + 8 * K, b + 8 * K);
}

// static inline void schoolbook_KxK(uint16_t r[2 * K], const uint16_t a[K], const uint16_t b[K]) {
//     size_t i, j;
//     for (j = 0; j < K; j++) {
//         r[j] = a[0] * b[j];
//     }
//     for (i = 1; i < K; i++) {
//         for (j = 0; j < K - 1; j++) {
//             r[i + j] += a[i] * (uint16_t)b[j];
//         }
//         r[i + K - 1] = a[i] * (uint16_t)b[K - 1];
//     }
//     r[2 * K - 1] = 0;
// }

/* Karatsuba Begin */

// static uint16_t a01[K];
// static uint16_t b01[K];
// static uint16_t c0[K];
// static uint16_t c1[K];
// static uint16_t c2[K];
//
// #define Kh (K >> 1)
//
// static inline void schoolbook_Kd2xKd2(uint16_t r[K], const uint16_t a[Kh], const uint16_t b[Kh]) {
//     size_t i, j;
//     for (j = 0; j < Kh; j++) {
//         r[j] = a[0] * b[j];
//     }
//
//     for (i = 1; i < Kh; i++) {
//         for (j = 0; j < Kh - 1; j++) {
//             r[i + j] += a[i] * b[j];
//         }
//         r[i + Kh - 1] = a[i] * b[Kh - 1];
//     }
//     r[K - 1] = 0;
// }
//
// static inline void karatsuba_KxK(uint16_t r[2 * K], const uint16_t a[K], const uint16_t b[K]) {
//   uint16x8_t vec0, vec1, vec2;
//   schoolbook_Kd2xKd2(c0, a + 0 * Kh, b + 0 * Kh);
//   schoolbook_Kd2xKd2(c2, a + 1 * Kh, b + 1 * Kh);
//   for (size_t i = 0; i < Kh; i++) {
//     a01[i] = a[i] + a[i + Kh];
//     b01[i] = b[i] + b[i + Kh];
//   }
//   schoolbook_Kd2xKd2(c1, a01, b01);
//
//   for (size_t i = 0; i < K; i++) {
//     c1[i] -= c0[i] + c2[i];
//   }
//
//   for (size_t i = 0; i < Kh; i++) {
//     r[i + 0 * Kh] = c0[i + 0 * Kh];
//     r[i + 1 * Kh] = c1[i + 0 * Kh] + c0[i + 1 * Kh];
//     r[i + 2 * Kh] = c2[i + 0 * Kh] + c1[i + 1 * Kh];
//     r[i + 3 * Kh] =                  c2[i + 1 * Kh];
//   }
// }

/* Karatsuba End */

static inline void schoolbook_KxK(uint16_t r[2 * K], const uint16_t a[K], const uint16_t b[K]) {
    size_t i, j;
    uint16x8_t a0_vec, ai_vec, b_vec, r_vec;

    a0_vec = vdupq_n_u16(a[0]);
    for (j = 0; j < Km8; j += 8) {
        b_vec = vld1q_u16(b + j);
        r_vec = vmulq_u16(a0_vec, b_vec);
        vst1q_u16(r + j, r_vec);
    }
    for (j = Km8; j < K; j++) {
        r[j] = a[0] * b[j];
    }

    for (i = 1; i < K; i++) {
        ai_vec = vdupq_n_u16(a[i]);
        for (j = 0; j < Km8; j += 8) {
            b_vec = vld1q_u16(b + j);
            r_vec = vld1q_u16(r + i + j);
            r_vec = vmlaq_u16(r_vec, ai_vec, b_vec);
            vst1q_u16(r + i + j, r_vec);
        }
        for (j = Km8; j < K - 1; j++) {
            r[i + j] += a[i] * b[j];
        }
        r[i + K - 1] = a[i] * b[K - 1];
    }
    r[2 * K - 1] = 0;
}

static void toom4_k2x2_interpolate(uint16_t r[2 * L], const uint16_t a[7 * 18 * K]) {
    size_t i;

    uint16_t P1[2 * M];
    uint16_t Pm1[2 * M];
    uint16_t P2[2 * M];
    uint16_t Pm2[2 * M];

    uint16_t *C0 = r;
    uint16_t *C2 = r + 2 * M;
    uint16_t *C4 = r + 4 * M;
    uint16_t *C6 = r + 6 * M;

    uint16_t V0, V1, V2;

    k2x2_interpolate(C0, a + 0 * 9 * 2 * K);
    k2x2_interpolate(P1, a + 1 * 9 * 2 * K);
    k2x2_interpolate(Pm1, a + 2 * 9 * 2 * K);
    k2x2_interpolate(P2, a + 3 * 9 * 2 * K);
    k2x2_interpolate(Pm2, a + 4 * 9 * 2 * K);
    k2x2_interpolate(C6, a + 6 * 9 * 2 * K);

    for (i = 0; i < 2 * M; i++) {
        V0 = ((uint32_t)(P1[i] + Pm1[i])) >> 1;
        V0 = V0 - C0[i] - C6[i];
        V1 = ((uint32_t)(P2[i] + Pm2[i] - 2 * C0[i] - 128 * C6[i])) >> 3;
        C4[i] = 43691 * (uint32_t)(V1 - V0);
        C2[i] = V0 - C4[i];
        P1[i] = ((uint32_t)(P1[i] - Pm1[i])) >> 1;
    }

    /* reuse Pm1 for P3 */
#define P3 Pm1
    k2x2_interpolate(P3, a + 5 * 9 * 2 * K);

    for (i = 0; i < 2 * M; i++) {
        V0 = P1[i];
        V1 = 43691 * (((uint32_t)(P2[i] - Pm2[i]) >> 2) - V0);
        V2 = 43691 * (uint32_t)(P3[i] - C0[i] - 9 * (C2[i] + 9 * (C4[i] + 9 * C6[i])));
        V2 = ((uint32_t)(V2 - V0)) >> 3;
        V2 -= V1;
        P3[i] = 52429 * (uint32_t)V2;
        P2[i] = V1 - V2;
        P1[i] = V0 - P2[i] - P3[i];
    }

    for (i = 0; i < 2 * M; i++) {
        r[1 * M + i] += P1[i];
        r[3 * M + i] += P2[i];
        r[5 * M + i] += P3[i];
    }
}

static inline void k2x2_interpolate(uint16_t r[2 * M], const uint16_t a[18 * K]) {
    size_t i;
    uint16_t tmp[4 * K];

    for (i = 0; i < 2 * K; i++) {
        r[0 * K + i] = a[0 * K + i];
        r[2 * K + i] = a[2 * K + i];
    }

    for (i = 0; i < 2 * K; i++) {
        r[1 * K + i] += a[8 * K + i] - a[0 * K + i] - a[2 * K + i];
    }

    for (i = 0; i < 2 * K; i++) {
        r[4 * K + i] = a[4 * K + i];
        r[6 * K + i] = a[6 * K + i];
    }

    for (i = 0; i < 2 * K; i++) {
        r[5 * K + i] += a[14 * K + i] - a[4 * K + i] - a[6 * K + i];
    }

    for (i = 0; i < 2 * K; i++) {
        tmp[0 * K + i] = a[12 * K + i];
        tmp[2 * K + i] = a[10 * K + i];
    }

    for (i = 0; i < 2 * K; i++) {
        tmp[K + i] += a[16 * K + i] - a[12 * K + i] - a[10 * K + i];
    }

    for (i = 0; i < 4 * K; i++) {
        tmp[0 * K + i] = tmp[0 * K + i] - r[0 * K + i] - r[4 * K + i];
    }

    for (i = 0; i < 4 * K; i++) {
        r[2 * K + i] += tmp[0 * K + i];
    }
}

// static inline void k2x2_interpolate(uint16_t r[2 * M], const uint16_t a[18 * K]) {
//     size_t i;
//     uint16_t tmp[4 * K];
//
//     uint16x8_t vec0, vec1, vec2, vec3;
//
//     for (i = 0; i < 2 * K; i += 8) {
//         vec0 = vld1q_u16(a + 0 * K + i);
//         vst1q_u16(r + 0 * K + i, vec0);
//         vec0 = vld1q_u16(a + 2 * K + i);
//         vst1q_u16(r + 2 * K + i, vec0);
//         vec0 = vld1q_u16(a + 4 * K + i);
//         vst1q_u16(r + 4 * K + i, vec0);
//         vec0 = vld1q_u16(a + 6 * K + i);
//         vst1q_u16(r + 6 * K + i, vec0);
//     }
//
//     for (i = 0; i < 2 * K; i += 8) {
//         // r[1 * K + i] += a[8 * K + i] - a[0 * K + i] - a[2 * K + i];
//         vec0 = vld1q_u16(a + 0 * K + i);
//         vec1 = vld1q_u16(a + 2 * K + i);
//         vec2 = vld1q_u16(a + 8 * K + i);
//         vec3 = vsubq_u16(vec2, vec0);
//         vec3 = vsubq_u16(vec3, vec1);
//         vec0 = vld1q_u16(r + 1 * K + i);
//         vec0 = vaddq_u16(vec0, vec3);
//         vst1q_u16(r + 1 * K + i, vec0);
//
//         // r[5 * K + i] += a[14 * K + i] - a[4 * K + i] - a[6 * K + i];
//         vec0 = vld1q_u16(a + 4 * K + i);
//         vec1 = vld1q_u16(a + 6 * K + i);
//         vec2 = vld1q_u16(a + 14 * K + i);
//         vec3 = vsubq_u16(vec2, vec0);
//         vec3 = vsubq_u16(vec3, vec1);
//         vec0 = vld1q_u16(r + 5 * K + i);
//         vec0 = vaddq_u16(vec0, vec3);
//         vst1q_u16(r + 5 * K + i, vec0);
//     }
//
//     for (i = 0; i < 2 * K; i += 8) {
//         vec0 = vld1q_u16(a + 12 * K + i);
//         vst1q_u16(tmp + 0 * K + i, vec0);
//         vec0 = vld1q_u16(a + 10 * K + i);
//         vst1q_u16(tmp + 2 * K + i, vec0);
//     }
//
//     for (i = 0; i < 2 * K; i += 8) {
//         // tmp[K + i] += a[16 * K + i] - a[12 * K + i] - a[10 * K + i];
//         vec0 = vld1q_u16(a + 10 * K + i);
//         vec1 = vld1q_u16(a + 12 * K + i);
//         vec2 = vld1q_u16(a + 16 * K + i);
//         vec3 = vsubq_u16(vec2, vec0);
//         vec3 = vsubq_u16(vec3, vec1);
//         vec0 = vld1q_u16(tmp + 1 * K + i);
//         vec0 = vaddq_u16(vec0, vec3);
//         vst1q_u16(tmp + 1 * K + i, vec0);
//     }
//
//     for (i = 0; i < 4 * K; i += 8) {
//         // tmp[0 * K + i] = tmp[0 * K + i] - r[0 * K + i] - r[4 * K + i];
//         vec0 = vld1q_u16(tmp + 0 * K + i);
//         vec1 = vld1q_u16(r + 0 * K + i);
//         vec2 = vld1q_u16(r + 4 * K + i);
//         vec0 = vsubq_u16(vec0, vec1);
//         vec0 = vsubq_u16(vec0, vec2);
//         vst1q_u16(tmp + 0 * K + i, vec0);
//         // vec1 = vld1q_u16(r + 2 * K + i);
//         // vec0 = vaddq_u16(vec0, vec1);
//         // vst1q_u16(r + 2 * K + i, vec0);
//     }
//
//     for (i = 0; i < 4 * K; i += 8) {
//         // r[2 * K + i] += tmp[0 * K + i];
//         vec0 = vld1q_u16(tmp + 0 * K + i);
//         vec1 = vld1q_u16(r + 2 * K + i);
//         vec1 = vaddq_u16(vec1, vec0);
//         vst1q_u16(r + 2 * K + i, vec1);
//     }
// }
