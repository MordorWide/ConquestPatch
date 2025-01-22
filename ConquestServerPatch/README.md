# MordorWide ConquestPatcher

This repository contains the source code to run the game server for `The Lord of the Rings: Conquest` using the EA Nation re-implementation MordorWide.

The application disables the SSL check and changes the endpoints from the shut-down EA servers to the re-implemented ones.

## How to Use

**Note:** Two options are possible, namely statically patching (only for decrypted/"cracked" exe files), or dynamically patching the game (supports both options).

### Static Patch
This approach patches the game binary directly. This is only possible because the decrypted game binary is not protected by SecuRom 7.38.0014 anymore.

1. Copy the file `Conquest.exe` (only decrypted/"cracked" files are supported) into a user directory you can write access to.
2. Obtain the `EANationStaticPatch.ps1` from here: [`EANationStaticPatch.ps1`](https://github.com/MordorWide/ConquestPatch/releases/latest)
3. Save the `EANationStaticPatch.ps1` file into a directory, preferably into the same user directory you used in step 1.
4. Open the PowerShell in **administrative mode**.
5. Enter the following steps into the shell window:
```powershell
# Allow the temporary execution of unsigned PowerShell scripts
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# Confirm with A

# Then, get into the user directory where the script is located (from step 3)
cd C:\Users\<username>
# Launch the EA Nation patch
.\EANationStaticPatch.ps1
```
6. Select the `Conquest.exe` in your user directory (from step 1).
7. Wait until all the patches have been applied. Note that the PowerShell script takes a few seconds for each pattern. There are 4-5 patterns in total.
8. Copy/Overwrite the patched `Conquest.exe` file back into the game directory. You may also keep the file `Conquest.exe.bak` file.
9. Launch the game and enter the EA Nation area to verify if the patch was successful.

### Dynamic Patch
This approach works for the genuine exe files protected by SecuRom as well as for the decrypted/"cracked" exe files.
It launches the protected game executable and patches the relevant memory positions as soon as the game code has been decrypted by the SecuRom loader.

1. Rename the file `Conquest.exe` in the game install directory into `OriginalConquest.exe`. **The exact file name is important!**
2. Get the patch loader from here: [`Conquest.exe`](https://github.com/MordorWide/ConquestPatch/releases/latest)
3. Save the `Conquest.exe` file from the webpage into the game install directory.
4. Launch the game by starting the new `Conquest.exe` file from the game install directory. A console window should show up and report the success of the patched endpoints after a few seconds.
5. Enter the EA Nation area to verify if the patch was successful.

**Note:** The console window might report errors at first, but should eventually report the successful patching and close itself after a few seconds.

**If it did not work, please create a new issue and submit details about your game binary.**


## Manual Build of the Dynamic Patch
If you want to build the program yourself, do the following steps:
1. Setup the Visual C++ compiler suite (e.g. VS 2022), including CMake, and the Windows SDK.
2. Run the following steps in the PowerShell window:
```powershell
# Add CMake to the PATH variable
$env:Path = 'C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;' + $env:Path

# Clone and enter this repository
git clone https://github.com/MordorWide/ConquestPatch ConquestPatch
cd ConquestPatch

# Prepare directory
mkdir build
cd build

# Make build scripts with x86 (32 bit) configuration
cmake -G "Visual Studio 17 2022" -A Win32 ..

# Build the exe file
cmake --build . --config Release

# Get the executable and cleanup the build directory
cd ..
cp build\Release\Conquest.exe Conquest.exe
rm -r build

# The file is compiled successfully.
```
