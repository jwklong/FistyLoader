#pragma once

extern "C" {
    extern const char** gooballIds;
    
    void FileSystemUtils_CreateDir(const char* path);
    
    bool SDL_ShowSimpleMessageBox(int flags, const char *title, const char *message, void *window);
};
