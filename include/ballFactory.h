#pragma once

#include "wog2/templateInfo.h"

struct BallTemplateInfoExt {
    BallTemplateInfo base;
    
    ImageIdInfo editorButtonImageId;
};

extern "C" {
    size_t getTemplateInfoOffset(int i);
    BallTemplateInfo* getTemplateInfoError(const char* id);
}
