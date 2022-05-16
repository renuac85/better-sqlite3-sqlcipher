#!/usr/bin/env bash

# ===
# This script defines and generates the bundled SQLite3 unit (sqlite3.c).
#
# The following steps are taken:
# 1. populate the shell environment with the defined compile-time options.
# 2. download and extract the SQLite3 source code into a temporary directory.
# 3. run "sh configure" and "make sqlite3.c" within the source directory.
# 4. copy the generated amalgamation into the output directory (./sqlite3).
# 5. export the defined compile-time options to a gyp file (./defines.gypi).
# 6. update the docs (../docs/compilation.md) with details of this distribution.
#
# When a user builds better-sqlite3, the following steps are taken:
# 1. node-gyp loads the previously exported compile-time options (defines.gypi).
# 2. the copy.js script copies the bundled amalgamation into the build folder.
# 3. node-gyp compiles the copied sqlite3.c along with better_sqlite3.cpp.
# 4. node-gyp links the two resulting binaries to generate better_sqlite3.node.
# ===

YEAR="2022"
VERSION="3380500"

DEFINES="
SQLITE_DQS=0
SQLITE_LIKE_DOESNT_MATCH_BLOBS
SQLITE_THREADSAFE=2
SQLITE_USE_URI=0
SQLITE_DEFAULT_MEMSTATUS=0
SQLITE_OMIT_DEPRECATED
SQLITE_OMIT_GET_TABLE
SQLITE_OMIT_TCL_VARIABLE
SQLITE_OMIT_PROGRESS_CALLBACK
SQLITE_OMIT_SHARED_CACHE
SQLITE_TRACE_SIZE_LIMIT=32
SQLITE_DEFAULT_CACHE_SIZE=-16000
SQLITE_DEFAULT_FOREIGN_KEYS=1
SQLITE_DEFAULT_WAL_SYNCHRONOUS=1
SQLITE_ENABLE_MATH_FUNCTIONS
SQLITE_ENABLE_DESERIALIZE
SQLITE_ENABLE_COLUMN_METADATA
SQLITE_ENABLE_UPDATE_DELETE_LIMIT
SQLITE_ENABLE_STAT4
SQLITE_ENABLE_FTS3_PARENTHESIS
SQLITE_ENABLE_FTS3
SQLITE_ENABLE_FTS4
SQLITE_ENABLE_FTS5
SQLITE_ENABLE_JSON1
SQLITE_ENABLE_RTREE
SQLITE_ENABLE_GEOPOLY
SQLITE_INTROSPECTION_PRAGMAS
SQLITE_SOUNDEX
HAVE_STDINT_H=1
HAVE_INT8_T=1
HAVE_INT16_T=1
HAVE_INT32_T=1
HAVE_UINT8_T=1
HAVE_UINT16_T=1
HAVE_UINT32_T=1
"

# ========== START SCRIPT ========== #

echo "setting up environment..."
DEPS="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
TEMP="$DEPS/temp"
OUTPUT="$DEPS/sqlite3"
rm -rf "$TEMP"
rm -rf "$OUTPUT"
mkdir -p "$TEMP"
mkdir -p "$OUTPUT"
export CFLAGS=`echo $(echo "$DEFINES" | sed -e "/^\s*$/d" -e "s/^/-D/")`

echo "downloading source..."
curl -#f "https://www.sqlite.org/$YEAR/sqlite-src-$VERSION.zip" > "$TEMP/source.zip" || exit 1

echo "extracting source..."
unzip "$TEMP/source.zip" -d "$TEMP" > /dev/null || exit 1
cd "$TEMP/sqlite-src-$VERSION" || exit 1

echo "configuring amalgamation..."
sh configure > /dev/null || exit 1

echo "building amalgamation..."
make sqlite3.c > /dev/null || exit 1

echo "copying amalgamation..."
cp sqlite3.c sqlite3.h sqlite3ext.h "$OUTPUT/" || exit 1

echo "updating gyp configs..."
GYP="$DEPS/defines.gypi"
printf "# THIS FILE IS AUTOMATICALLY GENERATED (DO NOT EDIT)\n\n{\n  'defines': [\n" > "$GYP"
printf "$DEFINES" | sed -e "/^\s*$/d" -e "s/\(.*\)/    '\1',/" >> "$GYP"
printf "  ],\n}\n" >> "$GYP"

echo "updating docs..."
DOCS="$DEPS/../docs/compilation.md"
MAJOR=`expr "${VERSION:0:1}" + 0`
MINOR=`expr "${VERSION:1:2}" + 0`
PATCH=`expr "${VERSION:3:2}" + 0`
sed -Ei.bak -e "s/version [0-9]+\.[0-9]+\.[0-9]+/version $MAJOR.$MINOR.$PATCH/g" "$DOCS"
sed -i.bak -e "/^SQLITE_/,\$d" "$DOCS"
rm "$DOCS".bak
printf "$DEFINES" | sed -e "/^\s*$/d" >> "$DOCS"
printf "\`\`\`\n" >> "$DOCS"

echo "cleaning up..."
cd - > /dev/null || exit 1
rm -rf "$TEMP"

echo "done!"
