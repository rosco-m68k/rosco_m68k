#include "py/runtime.h"

static mp_obj_t rosco_info(void) {
    mp_printf(&mp_plat_print, "Add board features etc...\n");
    return mp_const_none;
}
static MP_DEFINE_CONST_FUN_OBJ_0(rosco_info_obj, rosco_info);

static const mp_rom_map_elem_t rosco_module_globals_table[] = {
    { MP_OBJ_NEW_QSTR(MP_QSTR___name__), MP_OBJ_NEW_QSTR(MP_QSTR_rosco) },
    { MP_ROM_QSTR(MP_QSTR_info), MP_ROM_PTR(&rosco_info_obj) },
};
static MP_DEFINE_CONST_DICT(rosco_module_globals, rosco_module_globals_table);

const mp_obj_module_t rosco_module = {
    .base = { &mp_type_module },
    .globals = (mp_obj_dict_t *)&rosco_module_globals,
};

MP_REGISTER_MODULE(MP_QSTR_rosco, rosco_module);