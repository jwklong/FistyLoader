#pragma once

#include "wog2/templateInfo.h"
#include "wog2/ballFactory.h"
#include "ballTable.h"

template <typename TemplateInfo>
inline TemplateInfo* BallFactory<TemplateInfo>::getTemplateInfo(int typeEnum) {
    if (typeEnum < 0 || typeEnum >= gooballCount || !m_templateInfos[typeEnum].isInitialized()) {
        char buffer[0x40];
        snprintf(buffer, sizeof(buffer),
            "Error loading gooball:\n"
            "Unknown typeEnum %d.\n", typeEnum);
        
        SDL_ShowSimpleMessageBox(0x10, "Fisty Loader", buffer, 0);
        return nullptr;
    }
    
    return &m_templateInfos[typeEnum];
}

struct BallTemplateInfoExt {
    BallTemplateInfo base;
    
    ImageIdInfo editorButtonImageId;
};

extern "C" {
    size_t getTemplateInfoOffset(int i);
}
