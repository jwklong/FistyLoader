#include "wog2/templateInfo.h"
#include "wog2/ballFactory.h"
#include "ballFactory.h"
#include "ballTable.h"
#include "log.h"

extern "C" {

size_t getTemplateInfoOffset(int i) {
    return i * sizeof(BallTemplateInfoExt);
}

void ballDeserializeDebug(int ballType) {
#ifdef ENABLE_LOGGING
    const char* ballId = customGooballIds[ballType];
    print("Deserializing gooball %s\n", ballId);
#endif
}

void ballPartDeserializeDebug(const char* name) {
#ifdef ENABLE_LOGGING
    print("Deserializing ball part %s\n", name);
#endif
}

}

// explicitly instantiate getTemplateInfo
template BallTemplateInfoExt* BallFactory<BallTemplateInfoExt>::getTemplateInfo(int typeEnum);
