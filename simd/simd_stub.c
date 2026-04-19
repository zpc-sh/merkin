/*
 * merkin/simd — AVX-VNNI + AVX-NE-CONVERT stubs
 *
 * Intrinsics are static inline macros; MoonBit cannot call them directly.
 * This file wraps each intrinsic in a real C function symbol.
 *
 * #pragma GCC target scopes the instruction-set enablement to this TU only.
 * The rest of the build does not need -mavx-vnni or -mavx-ne-convert.
 *
 * Runtime guard: always call merkin_simd_caps() before the hot path.
 * If the CPU lacks AVX-VNNI the VNNI functions must not be invoked.
 */

/* ── target enablement ──────────────────────────────────────────────────── */
#pragma GCC target("avx2,avxvnni")

#include <immintrin.h>
#include <stdint.h>
#include <string.h>

/* ── runtime capability detection ──────────────────────────────────────── */

static inline void
cpuid(uint32_t leaf, uint32_t subleaf,
      uint32_t *eax, uint32_t *ebx, uint32_t *ecx, uint32_t *edx) {
  __asm__ __volatile__(
    "cpuid"
    : "=a"(*eax), "=b"(*ebx), "=c"(*ecx), "=d"(*edx)
    : "a"(leaf), "c"(subleaf)
  );
}

/*
 * merkin_simd_caps — bitmask of available SIMD features.
 *   bit 0: AVX2
 *   bit 1: AVX-VNNI   (CPUID.7.0:EDX[4])
 *   bit 2: AVX-NE-CONVERT (CPUID.7.1:EAX[5])
 */
int32_t merkin_simd_caps(void) {
  uint32_t eax, ebx, ecx, edx;
  int32_t caps = 0;

  cpuid(1, 0, &eax, &ebx, &ecx, &edx);
  int have_avx2_base = (ecx >> 28) & 1; /* OSXSAVE */

  if (!have_avx2_base) return 0;

  cpuid(7, 0, &eax, &ebx, &ecx, &edx);
  if (ebx & (1u << 5))  caps |= 1; /* AVX2 */
  if (edx & (1u << 4))  caps |= 2; /* AVX-VNNI */

  cpuid(7, 1, &eax, &ebx, &ecx, &edx);
  if (eax & (1u << 5))  caps |= 4; /* AVX-NE-CONVERT */

  return caps;
}

/* ── AVX-VNNI ───────────────────────────────────────────────────────────── */
/*
 * VPDPBUSD: acc[i] += a[4i]*b[4i] + a[4i+1]*b[4i+1] + ...
 *   a: uint8_t (unsigned)
 *   b: int8_t  (signed)
 *   acc: int32_t lanes
 *
 * Processes 32 bytes per call, producing 8 int32 dot-product lanes.
 * Each lane accumulates 4 consecutive (a,b) pairs.
 */

/*
 * merkin_vnni_dot32 — single-shot dot product over 32 bytes.
 * Sums all 8 lanes → one int32 result.
 * Useful for: single-pass similarity score between two 32-byte blobs.
 */
int32_t merkin_vnni_dot32(const uint8_t *a, const int8_t *b) {
  __m256i va  = _mm256_loadu_si256((const __m256i *)a);
  __m256i vb  = _mm256_loadu_si256((const __m256i *)b);
  __m256i acc = _mm256_setzero_si256();
  acc = _mm256_dpbusd_epi32(acc, va, vb);

  /* horizontal sum of 8 int32 lanes */
  __m128i lo  = _mm256_castsi256_si128(acc);
  __m128i hi  = _mm256_extracti128_si256(acc, 1);
  __m128i sum = _mm_add_epi32(lo, hi);
  sum = _mm_hadd_epi32(sum, sum);
  sum = _mm_hadd_epi32(sum, sum);
  return _mm_cvtsi128_si32(sum);
}

/*
 * merkin_vnni_dot32_lanes — dot product, raw 8 lanes, no horizontal sum.
 * out must point to int32_t[8].
 * Useful for: keeping per-lane accumulators across multiple calls.
 */
void merkin_vnni_dot32_lanes(const uint8_t *a, const int8_t *b, int32_t *out) {
  __m256i va  = _mm256_loadu_si256((const __m256i *)a);
  __m256i vb  = _mm256_loadu_si256((const __m256i *)b);
  __m256i acc = _mm256_setzero_si256();
  acc = _mm256_dpbusd_epi32(acc, va, vb);
  _mm256_storeu_si256((__m256i *)out, acc);
}

/*
 * merkin_vnni_accumulate — accumulate over `blocks` × 32-byte chunks.
 * out: int32_t[8] initialized by caller (can carry across calls).
 * This is the main loop for long-input hashing/scoring.
 */
void merkin_vnni_accumulate(const uint8_t *a, const int8_t *b,
                            int32_t blocks, int32_t *out) {
  __m256i acc = _mm256_loadu_si256((const __m256i *)out);
  for (int32_t i = 0; i < blocks; i++) {
    __m256i va = _mm256_loadu_si256((const __m256i *)(a + i * 32));
    __m256i vb = _mm256_loadu_si256((const __m256i *)(b + i * 32));
    acc = _mm256_dpbusd_epi32(acc, va, vb);
  }
  _mm256_storeu_si256((__m256i *)out, acc);
}

/*
 * merkin_vnni_fnv_x8 — 8-lane parallel FNV-1a over arbitrary bytes.
 *
 * Each lane starts from a different seed and mixes the same input bytes.
 * Output: 8 independent 32-bit hashes — richer bloom positions than
 * the current 3-hash scheme, at ~same compute cost for long inputs.
 *
 * out: int32_t[8]
 * data: byte array of length `len`
 */
void merkin_vnni_fnv_x8(const uint8_t *data, int32_t len, int32_t *out) {
  /* 8 different FNV-1a offset bases */
  static const int32_t seeds[8] = {
    (int32_t)0x811c9dc5u, (int32_t)0xc4a7c29bu,
    (int32_t)0x27364b3fu, (int32_t)0x4b9ace47u,
    (int32_t)0x9e3779b9u, (int32_t)0x6b43a9b5u,
    (int32_t)0x3c6ef372u, (int32_t)0x85ebca6bu,
  };
  const int32_t fnv_prime = (int32_t)0x01000193u;

  __m256i acc   = _mm256_loadu_si256((const __m256i *)seeds);
  __m256i prime = _mm256_set1_epi32(fnv_prime);

  for (int32_t i = 0; i < len; i++) {
    /* XOR each lane with the current byte */
    __m256i byte_v = _mm256_set1_epi32((int32_t)data[i]);
    acc = _mm256_xor_si256(acc, byte_v);
    /* Multiply by FNV prime (regular mullo — VNNI does uint8×int8,
       we still need mullo for the 32-bit multiply step) */
    acc = _mm256_mullo_epi32(acc, prime);
  }
  _mm256_storeu_si256((__m256i *)out, acc);
}

/*
 * merkin_vnni_bloom_positions — extract 8 bloom bit positions from fnv_x8 output.
 * hashes: int32_t[8] from merkin_vnni_fnv_x8
 * bit_count: total bits in the bloom filter (must be power of 2)
 * out: uint32_t[8] — bit positions (masked to bit_count-1)
 */
void merkin_vnni_bloom_positions(const int32_t *hashes, int32_t bit_count,
                                 int32_t *out) {
  __m256i vh   = _mm256_loadu_si256((const __m256i *)hashes);
  __m256i mask = _mm256_set1_epi32(bit_count - 1);
  __m256i pos  = _mm256_and_si256(vh, mask);
  _mm256_storeu_si256((__m256i *)out, pos);
}

/* ── AVX-NE-CONVERT ─────────────────────────────────────────────────────── */
/*
 * These require -mavx-ne-convert (or #pragma GCC target("avxneconvert")).
 * They are compiled into this TU but gated at runtime via merkin_simd_caps().
 * On CPUs without NE-CONVERT the symbols still exist; DO NOT CALL THEM
 * unless caps bit 2 is set.
 *
 * Providing them here means the binary is forward-compatible: when Loc
 * runs this on Granite Rapids / future hardware, they activate automatically.
 */

#ifdef __AVXNECONVERT__

/*
 * merkin_ne_bf16_to_f32_even — convert 8 bfloat16 values (even elements)
 * from a 16-element __m256bh-sized source to 8 floats.
 * src: uint16_t[16] (bf16 vector, 32 bytes)
 * dst: float[8]
 */
void merkin_ne_bf16_to_f32_even(const uint16_t *src, float *dst) {
  __m128i s = _mm_loadu_si128((const __m128i *)src);
  __m256 r  = _mm256_cvtneebf16_ps((__m128bh)s);
  _mm256_storeu_ps(dst, r);
}

/*
 * merkin_ne_bf16_to_f32_odd — convert odd elements of 8 bf16 pairs to float.
 */
void merkin_ne_bf16_to_f32_odd(const uint16_t *src, float *dst) {
  __m128i s = _mm_loadu_si128((const __m128i *)src);
  __m256 r  = _mm256_cvtneobf16_ps((__m128bh)s);
  _mm256_storeu_ps(dst, r);
}

/*
 * merkin_ne_broadcast_bf16 — broadcast one bf16 scalar to 8 floats.
 * scalar: bf16 value packed in low 16 bits of a uint32
 * dst: float[8]
 */
void merkin_ne_broadcast_bf16(int32_t scalar, float *dst) {
  uint16_t s = (uint16_t)(scalar & 0xFFFF);
  uint16_t buf[8];
  for (int i = 0; i < 8; i++) buf[i] = s;
  __m128i v = _mm_loadu_si128((const __m128i *)buf);
  __m256 r  = _mm256_cvtneebf16_ps((__m128bh)v);
  _mm256_storeu_ps(dst, r);
}

#else  /* __AVXNECONVERT__ not available at compile time */

void merkin_ne_bf16_to_f32_even(const uint16_t *src, float *dst) {
  /* scalar fallback: bf16 = sign|exp8|mant7 → f32 = sign|exp8|mant23 */
  for (int i = 0; i < 8; i++) {
    uint32_t bits = (uint32_t)src[i * 2] << 16;
    memcpy(&dst[i], &bits, 4);
  }
}

void merkin_ne_bf16_to_f32_odd(const uint16_t *src, float *dst) {
  for (int i = 0; i < 8; i++) {
    uint32_t bits = (uint32_t)src[i * 2 + 1] << 16;
    memcpy(&dst[i], &bits, 4);
  }
}

void merkin_ne_broadcast_bf16(int32_t scalar, float *dst) {
  uint32_t bits = (uint32_t)(scalar & 0xFFFF) << 16;
  float f;
  memcpy(&f, &bits, 4);
  for (int i = 0; i < 8; i++) dst[i] = f;
}

#endif /* __AVXNECONVERT__ */
