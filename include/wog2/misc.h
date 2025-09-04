#pragma once

#include <cstddef>

extern "C" {
    extern const char* gooballIds[0x27];
    
    int snprintf ( char * s, size_t n, const char * format, ... );
    
    void FileSystemUtils_CreateDir(const char* path);
    
    bool SDL_ShowSimpleMessageBox(int flags, const char *title, const char *message, void *window);
};
