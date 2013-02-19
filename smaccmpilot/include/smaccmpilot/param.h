/* This file has been autogenerated by Ivory
 * Compiler version  0.1.0.0
 */
#ifndef __PARAM_H__
#define __PARAM_H__
#ifdef __cplusplus
extern "C" {
#endif
#include <ivory.h>
#include "console.h"
#include "ivory_string.h"
#include "smavlink_pack_ivory.h"
#include "storage_partition.h"
struct param_info {
    uint8_t param_type;
    char param_name[17U];
    int32_t param_index;
    uint8_t* param_ptr_u8;
    uint16_t* param_ptr_u16;
    uint32_t* param_ptr_u32;
    float* param_ptr_float;
    uint8_t param_requested;
};
struct param_header {
    uint32_t ph_signature;
    uint8_t ph_seq;
    uint16_t ph_length;
};
struct param_info* param_new();
void param_init_u8(char* n_var0, uint8_t* n_var1);
void param_init_u16(char* n_var0, uint16_t* n_var1);
void param_init_u32(char* n_var0, uint32_t* n_var1);
void param_init_float(char* n_var0, float* n_var1);
struct param_info* param_get_by_name(const char* n_var0);
struct param_info* param_get_by_index(int32_t n_var0);
struct param_info* param_get_requested();
float param_get_float_value(struct param_info* n_var0);
void param_set_float_value(struct param_info* n_var0, float n_var1);
bool param_read_header(int32_t n_var0, struct param_header* n_var1);
bool param_write_header(int32_t n_var0, const struct param_header* n_var1);
bool param_is_valid_header(const struct param_header* n_var0);
bool param_is_valid_seq(uint8_t n_var0);
uint8_t param_get_next_seq(uint8_t n_var0);
int32_t param_get_next_pid(int32_t n_var0);
int32_t param_choose_partition(const struct param_header* n_var0, const
                               struct param_header* n_var1);
bool param_load_1(int32_t n_var0, uint16_t n_var1);
bool param_load_all(int32_t n_var0, struct param_header* n_var1);
bool param_load();
bool param_save_1(int32_t n_var0, uint16_t n_var1, struct param_info* n_var2);
bool param_save();
extern struct param_info g_param_info[512U];
extern int32_t g_param_count;
extern int32_t g_param_next_pid;
extern uint8_t g_param_next_seq;

#ifdef __cplusplus
}
#endif
#endif /* __PARAM_H__ */