
# How to compile
```
make
```

# Test for correctness
```
./test
```

## Sample output
```
poly_Rq_mul_small passed!
```

# Benchmark
```
./speed
```

## Sample output
```
poly_Rq_mul_small: 91562
```

# What you can modify
```
make_opt.mk
poly.h
poly.c
```
If you wish to add your own files for compilation, specify the file names in `make_opt.mk`.

# What you should not modify
```
Makefile
hal-cortexa.c
hal.h
params.h
speed.c
test.c
```

# Thresholds

## First threshold
* `polymul_small < 78000`

## Second threshold
* `polymul_small < 62000`

## Third threshold
* `polymul_small < 48000`

# State of the art
Paper **Fast NEON-Based Multiplication for Lattice-Based NIST Post-quantum Cryptography Finalists** at
https://link.springer.com/chapter/10.1007/978-3-030-81293-5_13
* `polymul_small < 56000`
You're right, we believe it is possible to outperform the state of the art.













