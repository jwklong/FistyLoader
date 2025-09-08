#include "wog2/templateInfo.h"
#include "wog2/ballFactory.h"
#include "ballFactory.h"
#include "ballTable.h"

extern "C" {

size_t getTemplateInfoOffset(int i) {
    return i * sizeof(BallTemplateInfo);
}

}

// explicitly instantiate getTemplateInfo
template BallTemplateInfo* BallFactory<BallTemplateInfo>::getTemplateInfo(int typeEnum);
