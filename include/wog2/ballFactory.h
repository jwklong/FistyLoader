#pragma once

#include "wog2/misc.h"
#include "wog2/templateInfo.h"

struct BallFactory {
public:
    virtual void destructorWorkaround();
    
    BallTemplateInfo* getTemplateInfo(int typeEnum);
    BallTemplateInfo* getTemplateInfo(const std::string& id);
    
private:
    BallTemplateInfo* m_templateInfos;
    int m_ballCount;
    
    // originally, there would be a static array here
    // with the asm patches, this data structure is dynamically sized :D
};
