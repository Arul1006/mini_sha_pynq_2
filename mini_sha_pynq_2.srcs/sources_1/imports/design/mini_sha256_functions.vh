`ifndef MINI_SHA256_FUNCTIONS_VH
`define MINI_SHA256_FUNCTIONS_VH

// 16-bit specific rotations and shifts
`define ROTR16(x, n) (((x) >> (n)) | ((x) << (16 - (n))))
`define SHR16(x, n)  ((x) >> (n))

// Upper sigmas for round compression (16-bit)
`define SIGMA_UPPER_0(x) (`ROTR16(x, 1) ^ `ROTR16(x, 6) ^ `ROTR16(x, 11))
`define SIGMA_UPPER_1(x) (`ROTR16(x, 3) ^ `ROTR16(x, 5) ^ `ROTR16(x, 12))

// Lower sigmas for message schedule expansion (16-bit)
`define SIGMA_LOWER_0(x) (`ROTR16(x, 3) ^ `ROTR16(x, 7) ^ `SHR16(x, 1))
`define SIGMA_LOWER_1(x) (`ROTR16(x, 8) ^ `ROTR16(x, 9) ^ `SHR16(x, 5))

// Ch and Maj are independent of word size (bitwise)
`define CH(x, y, z)  (((x) & (y)) ^ (~(x) & (z)))
`define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))

`endif
