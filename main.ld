SDL_ShowSimpleMessageBox = 0x8944b0;

loading_screen_hook_return = 0x350131;
loading_screen_draw_hook_return = 0x350c20;

SECTIONS
{
    . = 0x24FC000;
    .fisty : {
        *(.fisty)
    }
}