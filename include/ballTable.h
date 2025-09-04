#pragma once

#include "wog2/environment.h"

extern "C" {
    extern const char** customGooballIds;
    extern long gooballCount;
    
    void load_ball_table(Storage* storage);
};
