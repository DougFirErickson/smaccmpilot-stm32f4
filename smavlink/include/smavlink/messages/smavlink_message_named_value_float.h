#ifndef __SMAVLINK_MESSAGE_NAMED_VALUE_FLOAT_H__
#define __SMAVLINK_MESSAGE_NAMED_VALUE_FLOAT_H__
#ifdef __cplusplus
extern "C" {
#endif
#include <ivory.h>
#include <smavlink/channel.h>
#include <smavlink/system.h>
struct named_value_float_msg {
    uint32_t time_boot_ms;
    float value;
    uint8_t name[10U];
};
void smavlink_send_named_value_float(struct named_value_float_msg* var0,
                                     struct smavlink_out_channel* var1,
                                     struct smavlink_system* var2);

#ifdef __cplusplus
}
#endif
#endif /* __SMAVLINK_MESSAGE_NAMED_VALUE_FLOAT_H__ */