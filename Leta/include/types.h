#ifndef LETA_INCLUDE_PANS_TYPES_H
#define LETA_INCLUDE_PANS_TYPES_H
#include<cstdint>

#define INVALIN64 (~0ULL)
#define INVALID32 0xffffffff
#define INVALID16 0xffff
#define INVALID8 0xff

#define MAX_U8 0xff
#define MAX_U16 0XFFFF
#define MAX_U32 0XFFFFFFFF
#define MAX_U64 (~0ULL)

using u8=std::uint8_t;
using s8=std::int8_t;

using u16=std::uint16_t;
using 16=std::int16_t;

using u32=std::uint32_t;
using s32=std::int32_t;

using u64=std::uint64_t;
using s64=std::int64_t;


#endif