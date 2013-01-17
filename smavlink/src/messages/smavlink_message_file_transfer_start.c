#include <smavlink/pack.h>
#include "smavlink_message_file_transfer_start.h"
void smavlink_send_file_transfer_start(struct file_transfer_start_msg* var0,
                                       struct smavlink_out_channel* var1,
                                       struct smavlink_system* var2)
{
    uint8_t local0[254U] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    uint8_t(* ref1)[254U] = &local0;
    uint64_t deref2 = *&var0->transfer_uid;
    
    smavlink_pack_uint64_t(ref1, 0, deref2);
    
    uint32_t deref3 = *&var0->file_size;
    
    smavlink_pack_uint32_t(ref1, 8, deref3);
    
    uint8_t deref4 = *&var0->direction;
    
    smavlink_pack_uint8_t(ref1, 252, deref4);
    
    uint8_t deref5 = *&var0->flags;
    
    smavlink_pack_uint8_t(ref1, 253, deref5);
    
    uint8_t(* let6)[240U] = &var0->dest_path;
    uint8_t ix7 = 0 % 240;
    
    for (; ix7 < 239 % 240; ix7 = ix7 + 1 % 240) {
        uint8_t deref8 = *&*let6[ix7];
        
        smavlink_pack_uint8_t(ref1, 12 + ix7, deref8);
    }
    smavlink_send_ivory(var1, var2, 110, ref1, 254, 235);
    return;
}
