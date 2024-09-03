# Fisty's exe Mod Loader

Fisty swore he would never be like those tadpoles that modify World of Goo 2's executable to allow for more types of user-made content, like custom gooballs.

But he wondered what it might be like.

-the Sign Painter

## Installation (Windows)

Make sure you are on the latest version of World of Goo 2. Copy your World of Goo 2 directory into some new place if you haven't already so you don't overwrite the original game.

Download the [FistyLoader Installer](https://github.com/Darxoon/FistyLoader/releases) and run it. When it asks you to give it your World of Goo 2.exe file, drag and drop the new executable into the window and press enter, so it can patch the game.

After that is done, you can continue to [Usage](#usage).

## Installation (Mac or Linux)

FistyLoader currently only supports Windows so if you use Mac or Linux, you will have to get the Windows version working through tools like Wine, Lutris or Proton.

Make sure you have [Python 3](https://www.python.org/) and [nasm](https://nasm.us/) installed. Clone the repository and run these commands:

    pip install -r requirements.txt
    nasm patch/main.s -o patcher/custom_code.bin
    python3 patcher/install.py

Then follow the instructions in the installer.

## Usage

When you run the game for the first time, FistyLoader is going to create the file `ballTable.ini` in the newly created `World of Goo 2/fisty` folder.

To add new gooballs, create a folder for the ball type with a ball.wog2 and resources.xml file and add an entry with the same name to the end of the ballTable.ini file.

## Contact

For any discussion around World of Goo 2 modding or FistyLoader specifically, join the Goofans discord (https://discord.gg/6BEecnD) and discuss it in the #mod2-general channel.

You can also contact me directly, my name on discord is `darxoon`.
