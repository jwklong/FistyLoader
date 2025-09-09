#include "wog2/templateInfo.h"
#include "wog2/ballFactory.h"
#include "wog2/json.h"

#include "ballFactory.h"
#include "ballTable.h"
#include "log.h"

extern "C" {

size_t getTemplateInfoOffset(int i) {
    return i * sizeof(BallTemplateInfoExt);
}

static const char* defaultEditorButtonImage(int ballType) {
    switch (ballType) {
        case 1:    return "IMAGE_EDITOR_UI_BALLCOMMON";
        case 2:    return "IMAGE_EDITOR_UI_BALLALBINO";
        case 4:    return "IMAGE_EDITOR_UI_BALLBALLOON";
        case 0xb:  return "IMAGE_EDITOR_UI_BALLBALLOONEYE";
        case 3:    return "IMAGE_EDITOR_UI_BALLIVY";
        case 0x11: return "IMAGE_EDITOR_UI_BALLROPE";
        case 6:    return "IMAGE_EDITOR_UI_BALLANCHOR";
        case 8:    return "IMAGE_EDITOR_UI_BALLGOOPRODUCT";
        case 0xe:  return "IMAGE_EDITOR_UI_BALLGOOPRODUCTWHITE";
        case 0xc:  return "IMAGE_EDITOR_UI_BALLCONDUIT";
        case 7:    return "IMAGE_EDITOR_UI_BALLLAUNCHERL2B";
        case 0xd:  return "IMAGE_EDITOR_UI_BALLLAUNCHERL2L";
        case 9:    return "IMAGE_EDITOR_UI_BALLTHRUSTER";
        case 0x10: return "IMAGE_EDITOR_UI_BALLSTICKYBOMB";
        case 0x17: return "IMAGE_EDITOR_UI_BALLMATCHSTICK";
        case 0x19: return "IMAGE_EDITOR_UI_BALLFIREWORKS";
        case 0x1a: return "IMAGE_EDITOR_UI_LIGHTBALL";
        case 0xf:  return "IMAGE_EDITOR_UI_BALLGROW";
        case 0x20: return "IMAGE_EDITOR_UI_BALLSHRINK";
        case 0x21: return "IMAGE_EDITOR_UI_BALLJELLY";
        case 5:    return "IMAGE_EDITOR_UI_BALLGOOLFSINGLE";
        case 0x22: return "IMAGE_EDITOR_UI_BALLGOOLF";
        case 0x23: return "IMAGE_EDITOR_UI_BALLTHISWAYUP";
        case 0x25: return "IMAGE_EDITOR_UI_BALLEYE";
        case 0x12: return "IMAGE_EDITOR_UI_BALLBOUNCY";
        case 0x26: return "IMAGE_EDITOR_UI_BALLGOOPRODUCT";
        case 0x13: return "IMAGE_EDITOR_UI_BALLFISH";
        case 0x1b: return "IMAGE_EDITOR_UI_BALLFIREWORKS";
        case 0x1c: return "IMAGE_EDITOR_UI_BALLFIREWORKS";
        
        default:   return nullptr;
    }
}

bool BallTemplateInfo_deserializeExt(BallTemplateInfoExt* info, int ballType, const cJSON* json) {
    cJSON* editorButtonImage = cJSON_GetObjectItemCaseSensitive(json, "editorButtonImage");
    
    const char* defaultEditorButton = defaultEditorButtonImage(ballType);
    if (defaultEditorButton != nullptr) {
        strncpy(info->editorButtonImageId.imageId, defaultEditorButton, 0x40);
    }
    
    if (editorButtonImage != nullptr) {
        if (!cJSON_IsObject(editorButtonImage))
            return false;
        
        if (!GetImageIdInfo(info->editorButtonImageId, editorButtonImage))
            return false;
    }
    
#ifdef ENABLE_LOGGING
    print("deserializing gooball %d %s: %s\n", ballType, info->name, info->editorButtonImageId.imageId);
#endif
    
    return true;
}

}

// explicitly instantiate getTemplateInfo
template BallTemplateInfoExt* BallFactory<BallTemplateInfoExt>::getTemplateInfo(int typeEnum);
