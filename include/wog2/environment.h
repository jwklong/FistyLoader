#pragma once

#define UNK_RETURN void

class Storage {
public:
    // in gcc, the destructor takes up two vtable slots, in msvc only 1
    virtual void destructorWorkaround();
    
    virtual bool FileExists(const char* filePath);
    virtual UNK_RETURN FileOpen();
    virtual UNK_RETURN FileRead();
    virtual UNK_RETURN FileWrite();
    virtual UNK_RETURN FileClose();
    virtual UNK_RETURN FileFlush();
    virtual UNK_RETURN FileGetSize();
    virtual UNK_RETURN FindFilesInPack();
};

class Environment {
public:
    // there are so many that i do not care about lol
    // TODO: i should probably still document their vtable offsets
    virtual UNK_RETURN init();
    virtual UNK_RETURN destroy();
    virtual UNK_RETURN startMainLoop();
    virtual UNK_RETURN stopMainLoop();
    virtual UNK_RETURN isShuttingDown();
    virtual UNK_RETURN getTime();
    virtual UNK_RETURN getPreciseTime();
    virtual UNK_RETURN getPreciseTime2(); // what is this??
    virtual UNK_RETURN sleep();
    virtual UNK_RETURN getGraphics();
    virtual UNK_RETURN getVsync();
    virtual UNK_RETURN createTriStrip();
    virtual UNK_RETURN getWindowSize();
    virtual UNK_RETURN setWindowSize();
    virtual UNK_RETURN setMinimumWindowSize();
    virtual UNK_RETURN windowResized();
    virtual UNK_RETURN getMouseCount();
    virtual UNK_RETURN getMouse();
    virtual UNK_RETURN getFirstMouse();
    virtual UNK_RETURN getGamepadMouse();
    virtual UNK_RETURN getGameController();
    virtual UNK_RETURN getKeyboardCount();
    virtual UNK_RETURN getKeyboard();
    virtual UNK_RETURN showSystemMouse();
    virtual UNK_RETURN queryCurrentMouseInWindowPosition();
    virtual UNK_RETURN isTouchMode();
    virtual UNK_RETURN lockHardwareCursorPixelData();
    virtual UNK_RETURN unlockHardwareCursorPixelData();
    virtual UNK_RETURN getResourceManager();
    virtual UNK_RETURN getPersistenceLayer();
    virtual UNK_RETURN setLanguage();
    virtual UNK_RETURN getLanguage();
    virtual UNK_RETURN showError();
    virtual UNK_RETURN getHardwareId();
    virtual UNK_RETURN isFullScreen();
    virtual UNK_RETURN toggleFullScreen();
    virtual UNK_RETURN enableFullScreenToggle();
    virtual UNK_RETURN disableFullScreenToggle();
    virtual UNK_RETURN log();
    virtual UNK_RETURN setLogCallback();
    virtual UNK_RETURN dumpEnvironmentInfo();
    virtual UNK_RETURN setLogFile();
    
    virtual Storage* getStorage();
    
    // ... (28 more)
};

extern "C" {
    Environment* Environment_instance();
};
