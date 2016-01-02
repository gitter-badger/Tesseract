
# Tesseract Graphics

[![Join the chat at https://gitter.im/Exerro/Tesseract](https://badges.gitter.im/Exerro/Tesseract.svg)](https://gitter.im/Exerro/Tesseract?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Tesseract is a graphics library for ComputerCraft and possibly OpenComputers and (Dan's New Project) at some stage.

### How to install and use

Firstly, install a small OS that includes building tools: `pastebin run viz9UYXi`. Having been installed, it will create a `usr` folder in the computer. This will be invisible if you're looking in-game, but if looking through an external editor, it's there, and contains all your files.

Next, clone the repo or download the zip. Make a new folder called `graphics` inside the `usr` folder, copy `src` and `setup` into it (`graphics/src` and `graphics/setup`), then copy everything from the `utils` folder into the `usr` folder.

After that, enter the following commands into the shell:

```
require.lua
cd graphics
build run setup
```

To run the code, type `build debug` into the shell (while cd'd into the `graphics` folder).
