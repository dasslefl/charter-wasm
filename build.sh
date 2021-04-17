#!/bin/bash

# A simple, automatic caching build system for C / C++ applications
# 2020 Florian Daßler (florian.dassler@s2020.tu-chemnitz.de)
# Rev 5


# Configuration
cc="emcc"
cppc="em++"

cflags="-Wall"
cppflags="-Wall"

ld="emcc"
ldflags="-lm"

ar="emar"
arflags="-rsc"

bin="build/charter-wasm.js"
arfile="build/charter-wasm.a"

srcdir="src"
objdir="build"
# zusätzliche Files
objfiles=""
sourcefiles="tinyexpr/tinyexpr.c"

mkdir "$objdir" >/dev/null 2>&1

execute_echo() {
    echo $ $@
    $@
    exitcode=$?

    if [ "$exitcode" -ne 0 ]; then
        echo " --- ERROR DURING BUILD ---"
        echo "  The previous command exited with Code $exitcode"
        exit $exitcode
    fi
}
# in den Ordner des Skriptes springen
cd "$(dirname "$0")"

if [ "$1" == "clean" ]; then
    echo "Cleaning up..."
    execute_echo rm -r "$objdir"
    execute_echo rm -f "$bin"
    exit 0
fi

# C-Dateien
sourcefiles="$sourcefiles $(find "$srcdir" -name "*.c" -printf "%p ")"
# C++-Dateien
sourcefiles="$sourcefiles $(find "$srcdir" -name "*.cpp" -printf "%p ")"

files_changed="false"

echo "Compiling..."

read -ra arr <<< "$sourcefiles"
for srcfile in "${arr[@]}"; do

    srcfile_path=$(realpath "$srcfile") # voller Pfad der C-Datei

    # wenn Dateiname mit . beginnt ignorieren
    if echo "$srcfile_path" | grep -q "\/\."; then
        continue
    fi

    hash=$(md5sum "$srcfile" | head -c 8) # kurzer Hash des Quellcodes

    objfile="${objdir}/${hash}.o"

    objfiles="$objfiles $objfile"

    # Objekt-Datei nicht existent --> Build dieser notwendig
    if [ ! -f "$objfile" ]; then

        # C-Datei?
        if [ "$(echo -n $srcfile | tail -c 2)" = ".c" ]; then
            execute_echo "$cc" "$cflags" -o "$objfile" -c "$srcfile"
            files_changed="true"
        fi

        # CPP-Datei?
        if [ "$(echo -n $srcfile | tail -c 4)" = ".cpp" ]; then
            execute_echo "$cppc" "$cppflags" -o "$objfile" -c "$srcfile"
            files_changed="true"
        fi
    fi
done

if [ "$files_changed" == "true" ]; then
    
    if [ "$1" == "archive" ]; then
        echo "Generating object Archive..."
        execute_echo "$ar" "$arflags" "$arfile" "$objfiles" "$add_objfiles"
    else
        echo "Linking everything together..."
        execute_echo "$ld" "$cflags" -o "$bin" "$objfiles" "$add_objfiles" "$ldflags"
    fi

    echo "Cleaning up..."

    objfiles_all=$(find "$objdir" -name "*.o" -printf "%p ")

    read -ra arr <<< "$objfiles_all"
    for objfile_all in "${arr[@]}"; do
        # Datei wird nicht mehr benötigt
        if echo "$objfiles" |  grep -vFq "$objfile_all"; then
            execute_echo rm "$objfile_all"
        fi
    done

    echo "Sucessfully built $bin!"
else
    echo "No rebuild necessary."
    echo "Run $0 clean if you still want to rebuild the application."
fi

