#pragma once

#ifdef ENABLE_LOGGING

#include "wog2/environment.h"

Storage* printStorage;
FileHandle printHandle;

inline void initPrint(Storage* storage, FileHandle handle) {
    printStorage = storage;
    printHandle = handle;
}

template<typename... Ts>
void print(const char* fmt, Ts... args) {
    char buffer[0x80];
    int size = snprintf(buffer, sizeof(buffer), fmt, args...);
    printStorage->FileWrite(printHandle, buffer, size);
    printStorage->FileFlush(printHandle);
}

#endif
