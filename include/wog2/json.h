#pragma once

#include "wog2/templateInfo.h"

typedef int cJSON_bool;

struct cJSON;

extern "C" {
    // cJSON
    cJSON* cJSON_GetObjectItemCaseSensitive(const cJSON* const object, const char* const string);
    cJSON_bool cJSON_IsObject(const cJSON* const item);
    
    // custom SerializationJSON
    bool SerializationJSON_GetFloat(float& result, const cJSON* json, const char* fieldName, float defaultValue);
    bool SerializationJSON_GetInt(int& result, const cJSON* json, const char* fieldName, int defaultValue);
    bool SerializationJSON_GetBool(bool& result, const cJSON* json, const char* fieldName, bool defaultValue);
    bool SerializationJSON_GetString(char* result, int maxLen, const cJSON* json, const char* fieldName, const char* defaultValue);
    
    bool GetImageIdInfo(ImageIdInfo& result, const cJSON* json);
}
