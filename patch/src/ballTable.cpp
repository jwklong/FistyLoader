#include "wog2/misc.h"
#include "wog2/environment.h"
#include "ballTable.h"

extern "C" {

const char ballTablePath[] = "fisty/ballTable.ini";

void loadBallTable() {
    FileSystemUtils_CreateDir("fisty");
    
    Environment* environment = Environment_instance();
    Storage* storage = environment->getStorage();
    
    if (storage->FileExists(ballTablePath)) {
        load_ball_table(storage);
    } else {
        customGooballIds = gooballIds;
        gooballCount = 39;
        
        create_ball_table(storage);
        
        SDL_ShowSimpleMessageBox(0x40, "Fisty Loader",
            "Successfully extracted assets from exe file into 'World of Goo 2 "
            "(current installation's game directory)/game/fisty'", 0);
    }
}

}
