#ifndef __IVORY_SERIALIZE_PRIM_H__
#define __IVORY_SERIALIZE_PRIM_H__

#include <stdint.h>
#include <string.h>

#define CAT(X,Y) X##_##Y
// Indirection in case X,Y defined
#define C(X,Y) CAT(X,Y)

// Implementation dependent sizes.
#ifndef CONFIG_IVORY_SIZEOF_FLOAT
#define CONFIG_IVORY_SIZEOF_FLOAT 4
#endif

#ifndef CONFIG_IVORY_FLOAT_AREA_TY
#define CONFIG_IVORY_FLOAT_AREA_TY uint32_t
#endif

#ifndef CONFIG_IVORY_SIZEOF_DOUBLE
#define CONFIG_IVORY_SIZEOF_DOUBLE 8
#endif

#ifndef CONFIG_IVORY_DOUBLE_AREA_TY
#define CONFIG_IVORY_DOUBLE_AREA_TY uint64_t
#endif

/* Serializing can be done with type-aliasing in unions (since C99), memcpy, or
   turning off strict-aliasing (using compiler-specific pragmas). memcpy appears
   to be the most portable and produces the best assembly. (Direct casting is
   undefined.) See for details: http://blog.regehr.org/archives/959

   *** WARNING *** Depends on byte == 8bits (for sizeof and memcpy). This is
   most always the case.
*/

// Packing primitives:

static inline void ivory_serialize_pack_prim_1(uint8_t *dst, const uint8_t *src) {
	dst[0] = src[0];
}

static inline void ivory_serialize_pack_prim_2(uint8_t *dst, const uint8_t *src) {
#ifndef CONFIG_IVORY_SERIALIZE_ENDIAN_SWAP
	dst[0] = src[0];
	dst[1] = src[1];
#else
	dst[0] = src[1];
	dst[1] = src[0];
#endif
}

static inline void ivory_serialize_pack_prim_4(uint8_t *dst, const uint8_t *src) {
#ifndef CONFIG_IVORY_SERIALIZE_ENDIAN_SWAP
	dst[0] = src[0];
	dst[1] = src[1];
	dst[2] = src[2];
	dst[3] = src[3];
#else
	dst[0] = src[3];
	dst[1] = src[2];
	dst[2] = src[1];
	dst[3] = src[0];
#endif
}

static inline void ivory_serialize_pack_prim_8(uint8_t *dst, const uint8_t *src) {
#ifndef CONFIG_IVORY_SERIALIZE_ENDIAN_SWAP
	dst[0] = src[0];
	dst[1] = src[1];
	dst[2] = src[2];
	dst[3] = src[3];
	dst[4] = src[4];
	dst[5] = src[5];
	dst[6] = src[6];
	dst[7] = src[7];
#else
	dst[0] = src[7];
	dst[1] = src[6];
	dst[2] = src[5];
	dst[3] = src[4];
	dst[4] = src[3];
	dst[5] = src[2];
	dst[6] = src[1];
	dst[7] = src[0];
#endif
}

// Functions to take care of offset and cast any source type to correct prim size:
static inline void ivory_serialize_pack_uint8(uint8_t *dst, uint32_t offs, uint8_t src) {
  uint8_t tmp[1] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_1(dst + offs, tmp);
}

static inline void ivory_serialize_pack_int8(uint8_t *dst, uint32_t offs, int8_t src) {
  uint8_t tmp[1] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_1(dst + offs, tmp);
}

static inline void ivory_serialize_pack_uint16(uint8_t *dst, uint32_t offs, uint16_t src) {
  uint8_t tmp[2] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_2(dst + offs, tmp);
}

static inline void ivory_serialize_pack_int16(uint8_t *dst, uint32_t offs, int16_t src) {
  uint8_t tmp[2] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_2(dst + offs, tmp);
}

static inline void ivory_serialize_pack_uint32(uint8_t *dst, uint32_t offs, uint32_t src) {
  uint8_t tmp[4] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_4(dst + offs, tmp);
}

static inline void ivory_serialize_pack_int32(uint8_t *dst, uint32_t offs, int32_t src) {
  uint8_t tmp[4] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_4(dst + offs, tmp);
}

static inline void ivory_serialize_pack_float(uint8_t *dst, uint32_t offs, float src) {
  uint8_t tmp[CONFIG_IVORY_SIZEOF_FLOAT] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	C(ivory_serialize_pack_prim,CONFIG_IVORY_SIZEOF_FLOAT)(dst + offs, tmp);
}

static inline void ivory_serialize_pack_uint64(uint8_t *dst, uint32_t offs, uint64_t src) {
  uint8_t tmp[8] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_8(dst + offs, tmp);
}

static inline void ivory_serialize_pack_int64(uint8_t *dst, uint32_t offs, int64_t src) {
  uint8_t tmp[8] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	ivory_serialize_pack_prim_8(dst + offs, tmp);
}

static inline void ivory_serialize_pack_double(uint8_t *dst, uint32_t offs, double src) {
  uint8_t tmp[CONFIG_IVORY_SIZEOF_DOUBLE] = {0};
  memcpy(&tmp, &src, sizeof(tmp));
	C(ivory_serialize_pack_prim,CONFIG_IVORY_SIZEOF_DOUBLE)(dst + offs, tmp);
}

// Unpacking primitives:

static inline uint8_t ivory_serialize_unpack_prim_1(const uint8_t *src){
	return ((uint8_t) src[0] << 0);
}

static inline uint16_t ivory_serialize_unpack_prim_2(const uint8_t *src){
#ifndef CONFIG_IVORY_SERIALIZE_ENDIAN_SWAP
	return (((uint16_t) src[0] << 0) |
			((uint16_t) src[1] << 8));
#else
	return (((uint16_t) src[1] << 0) |
			((uint16_t) src[0] << 8));
#endif
}

static inline uint32_t ivory_serialize_unpack_prim_4(const uint8_t *src){
#ifndef CONFIG_IVORY_SERIALIZE_ENDIAN_SWAP
	return (((uint32_t) src[0] << 0)  |
			((uint32_t) src[1] << 8)  |
			((uint32_t) src[2] << 16) |
			((uint32_t) src[3] << 24));
#else
	return (((uint32_t) src[3] << 0)  |
			((uint32_t) src[2] << 8)  |
			((uint32_t) src[1] << 16) |
			((uint32_t) src[0] << 24));
#endif
}

static inline uint64_t ivory_serialize_unpack_prim_8(const uint8_t *src){
#ifndef CONFIG_IVORY_SERIALIZE_ENDIAN_SWAP
	return (((uint64_t) src[0] << 0)  |
			((uint64_t) src[1] << 8)  |
			((uint64_t) src[2] << 16) |
			((uint64_t) src[3] << 24) |
			((uint64_t) src[4] << 32) |
			((uint64_t) src[5] << 40) |
			((uint64_t) src[6] << 48) |
			((uint64_t) src[7] << 56));
#else
	return (((uint64_t) src[7] << 0)  |
			((uint64_t) src[6] << 8)  |
			((uint64_t) src[5] << 16) |
			((uint64_t) src[4] << 24) |
			((uint64_t) src[3] << 32) |
			((uint64_t) src[2] << 40) |
			((uint64_t) src[1] << 48) |
			((uint64_t) src[0] << 56));
#endif
}

// Functions to cast unpacked result to specific destination types:
static inline uint8_t ivory_serialize_unpack_uint8(const uint8_t *src, uint32_t offs) {
	uint8_t tmp = ivory_serialize_unpack_prim_1(src+offs);
	return tmp;
}

static inline int8_t ivory_serialize_unpack_int8(const uint8_t *src, uint32_t offs) {
	uint8_t t = ivory_serialize_unpack_prim_1(src+offs);
  int8_t tmp = 0;
  memcpy(&tmp, &t, sizeof(tmp));
  return tmp;
}

static inline uint16_t ivory_serialize_unpack_uint16(const uint8_t *src, uint32_t offs) {
	uint16_t tmp = ivory_serialize_unpack_prim_2(src+offs);
	return tmp;
}

static inline int16_t ivory_serialize_unpack_int16(const uint8_t *src, uint32_t offs) {
	uint16_t t = ivory_serialize_unpack_prim_2(src+offs);
  int16_t tmp = 0;
  memcpy(&tmp, &t, sizeof(tmp));
	return tmp;
}

static inline uint32_t ivory_serialize_unpack_uint32(const uint8_t *src, uint32_t offs) {
	uint32_t tmp = ivory_serialize_unpack_prim_4(src+offs);
	return tmp;
}

static inline int32_t ivory_serialize_unpack_int32(const uint8_t *src, uint32_t offs) {
	uint32_t t = ivory_serialize_unpack_prim_4(src+offs);
  int32_t tmp = 0;
  memcpy(&tmp, &t, sizeof(tmp));
	return tmp;
}

static inline float ivory_serialize_unpack_float(const uint8_t *src, uint32_t offs) {
	CONFIG_IVORY_FLOAT_AREA_TY t = C(ivory_serialize_unpack_prim,CONFIG_IVORY_SIZEOF_FLOAT)(src+offs);
  float tmp = 0;
  memcpy(&tmp, &t, sizeof(tmp));
	return tmp;
}

static inline uint64_t ivory_serialize_unpack_uint64(const uint8_t *src, uint32_t offs) {
	uint64_t tmp = ivory_serialize_unpack_prim_8(src+offs);
	return tmp;
}

static inline int64_t ivory_serialize_unpack_int64(const uint8_t *src, uint32_t offs) {
	uint64_t t = ivory_serialize_unpack_prim_8(src+offs);
  int64_t tmp = 0;
  memcpy(&tmp, &t, sizeof(tmp));
	return tmp;
}

static inline double ivory_serialize_unpack_double(const uint8_t *src, uint32_t offs) {
	CONFIG_IVORY_DOUBLE_AREA_TY t = C(ivory_serialize_unpack_prim,CONFIG_IVORY_SIZEOF_DOUBLE)(src+offs);
  double tmp = 0;
  memcpy(&tmp, &t, sizeof(tmp));
	return tmp;
}

#endif // __IVORY_SERIALIZE_PRIM_H__

