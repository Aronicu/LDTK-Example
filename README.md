# LDTK Example
An Example of using my Raylib wasm template for loading and rendering LDTK files <br>
[Play it here](https://aronicu.github.io/ldtk-example)

## Building

### Windows
```batch
.\build.bat
```

### WASM

#### Requirements
1. [emsdk](https://emscripten.org/docs/getting_started/downloads.html)

> [!NOTE]  
> In `build_web.bat`, you need to modify the path to where your `emsdk_env.bat` is located

```batch
.\build_web.bat

:: For running
cd build_web
python -m http.server
```

## References
* [odin-ldtk](https://github.com/jakubtomsu/odin-ldtk/tree/main)
