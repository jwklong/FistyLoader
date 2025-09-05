snprintf = 0x1e20b0;
malloc = 0x15825;
free = 0xd1cf;
isspace = 0xb103c0;
set_errno = 0xb11984;
get_errno = 0xb118f0;
strtol = 0x454d;
strncpy = 0xaf0210;

SDL_ShowSimpleMessageBox = 0x8944b0;
FileSystemUtils_CreateDir = 0x4667c0;
Environment_instance = 0x41ec40;

gooballIds = 0x12eede0;
empty_string = 0xe8898e;

loading_screen_hook_return = 0x350131;
loading_screen_draw_hook_return = 0x350c20;
load_config_hook_return = 0x48a255;
eolgizmo_hook_return = 0x22f408;
ballfactory_start_hook_return = 0x20e9ff;
ballfactory_loop_hook_return = 0x20ea96;
ballfactory_init_hook_return = 0x20e969;
ballfactory_constructor_hook1_return = 0x20e2d1;
ballfactory_constructor_hook2_return = 0x20e2ed;
get_template_info_hook_return = 0x20e8fe;
create_objects_hook_return = 0x2988a7;
ball_deserialize_hook_return = 0x214036;
itempipein_spawnball_hook_return = 0x2be7c0;
get_gooball_name_hook1_return = 0x27b601;
get_gooball_name_hook2_return = 0x27b740;
set_state_from_item_hook_return = 0x2c8887;
set_state_from_ball_hook_return = 0x2c7e67;
try_shoot_ball_hook_return = 0x2db790;

SECTIONS
{
    . = 0x24FC000;
    .fisty : {
        *(.fisty)
        *(.text)
    }
}
