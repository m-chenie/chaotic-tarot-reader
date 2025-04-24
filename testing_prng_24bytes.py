#!/usr/bin/env python3
"""
Raw (un-whitened) 2-D Hénon map in Q1.31 fixed-point
+ byte-level uniformity plots
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

# ------------------------------------------------------------
# 1.  Parameters / seeds   (match your Verilog test-bench)
# ------------------------------------------------------------
SAMPLES = 50_000            # number of words to generate

# 12-bit temperature / light sensor reading  (example 0x7A3 = 1955)
sensor12 = 0x07A3
x0_q31   = sensor12 << 19   # left-shift 12-bit value to Q1.31

# 32-bit fingerprint-mean seed (example value)
y0_q31   = 0x5E6F_7081

# Hénon constants in Q1.31  (α = 1.4, β = 0.3)
A_Q31 = 0xB333_3333
B_Q31 = 0x2666_6666
ONE   = 0x8000_0000
MASK  = 0xFFFF_FFFF

# ------------------------------------------------------------
# 2.  Fixed-point helpers
# ------------------------------------------------------------
def q31_mul(a: int, b: int) -> int:
    """signed Q1.31 × Q1.31 → Q1.31"""
    prod = (a * b) & 0xFFFF_FFFF_FFFF_FFFF  # 64-bit wrap-around
    if prod & (1 << 63):                    # sign-extend
        prod -= 1 << 64
    return (prod >> 31) & MASK

def henon_q31(x: int, y: int):
    """one iteration of 2-D Hénon map"""
    x_sq = q31_mul(x, x)
    ax2  = q31_mul(A_Q31, x_sq)
    xn1  = (ONE - ax2 + y) & MASK
    yn1  = q31_mul(B_Q31, x)
    return xn1, yn1

# ------------------------------------------------------------
# 3.  Generate raw stream (no whitening)
# ------------------------------------------------------------
xs = np.empty(SAMPLES, dtype=np.uint32)
x, y = x0_q31, y0_q31
for i in range(SAMPLES):
    x, y = henon_q31(x, y)
    xs[i] = x                 # store raw x_n

# ------------------------------------------------------------
# 4.  Analyse bytes 0-2 (LSB .. byte-2)
# ------------------------------------------------------------
def analyse_byte(byte_vals, idx):
    hist  = np.bincount(byte_vals, minlength=256)
    chi2, p = stats.chisquare(hist, f_exp=np.full(256, hist.sum()/256))
    print(f"byte {idx}  χ² p-value = {p:.4f}")

    plt.figure()
    plt.hist(byte_vals, bins=256, color='orange')
    plt.title(f"Histogram – byte {idx} (shift {idx*8})")
    plt.xlabel("value 0-255"); plt.ylabel("count")
    plt.tight_layout()

for idx, shift in enumerate((0, 8, 16)):           # last three bytes
    analyse_byte((xs >> shift) & 0xFF, idx)

# ------------------------------------------------------------
# 5.  Histogram of the least-significant 24 bits  (uniform check)
# ------------------------------------------------------------
vals24 = xs & 0x00FF_FFFF         # keep only the lowest 24 bits

plt.figure()
# range=(0, 2**24) forces the x-axis to be the real 24-bit values
plt.hist(vals24, bins=256, range=(0, 2**24), color='orange')
plt.title("Histogram of the LSB-24 of xₙ  ({} samples)".format(SAMPLES))
plt.xlabel("24-bit value  (0x000000 … 0xFFFFFF)")
plt.ylabel("count")
plt.tight_layout()
plt.show()

plt.figure()
plt.plot(np.arange(1000), vals24[:1000], '.-', markersize=2)
plt.title("LSB-24 values versus iteration  (first 1 000)")
plt.xlabel("iteration"); plt.ylabel("24-bit value")
plt.tight_layout()

plt.show()