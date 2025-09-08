#pragma once

#include "wog2/misc.h"
#include "wog2/templateInfo.h"

template<typename TemplateInfo>
struct BallFactory {
public:
    virtual void destructorWorkaround();
    
    TemplateInfo* getTemplateInfo(int typeEnum);
    TemplateInfo* getTemplateInfo(const std::string& id);
    
private:
    TemplateInfo* m_templateInfos;
    int m_ballCount;
    
    // originally, there would be a static array here
    // with the asm patches, this data structure is dynamically sized :D
};
