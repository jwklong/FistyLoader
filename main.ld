snprintf = 0x1e20b0;
malloc = 0x15825;
free = 0xd1cf;
isspace = 0xb103c0;
set_errno = 0xb11984;
get_errno = 0xb118f0;
strtol = 0x454d;
strncopy = 0xaf0210;

SDL_ShowSimpleMessageBox = 0x8944b0;
FileSystemUtils_CreateDir = 0x4667c0;
Environment_instance = 0x41ec40;

gooballIds = 0x12eede0;
empty_string = 0xe8898e;

loading_screen_hook_return = 0x350131;
loading_screen_draw_hook_return = 0x350c20;
load_config_hook_return = 0x48a255;
eolgizmo_hook_return = 0x22f408;

SECTIONS
{
    . = 0x24FC000;
    .fisty : {
        *(.fisty)
    }
}
