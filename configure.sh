#! /bin/bash
# If the colors doesn't work under OSX, get a newer version of bash and use that one
# You can also use zsh or disable color (WHY?!) with the -C optio with the -C optionn

# Configure script that generates a Makefile for a project located at a src/
# directory. This script doesn't check for compilers or anything as GNU
# Developers Tools does, so use at your own risk.
#
# To report a bug contact me at i@posva.net
# Written by Eduardo San Martin Morote aka Posva
# http://posva.net

# Some variables that can be changed through options
# -c gcc to change this
CXX="xcrun clang++" # Compiler

# Where are the files
# change with -s some-dir, same for -o and -b
SRC_DIR="src"
OBJ_DIR="obj"
BIN_DIR="bin"

# Default options passed to the compiler. You can pass more options or edit
# these as much as you want
# Use -D to supress these options (by these I mean all of the DEFAULT_ variables"
# Add new options with -O "-Wall -Os"
DEFAULT_OPTIONS="-Wall -Wextra -O2 -std=c++11 -stdlib=libc++"
OPTIONS=""
# Include directories default options
# Add new directories with -Isrc/
DEFAULT_INCLUDE="-I${SRC_DIR}"
INCLUDE=""
# Here is the linking step, add any library using the -l-lGL -l-lBox2D
# BEWARE OF THE DOUBLE -l, this is because in OS X you use -framework OpenGL and not -lGL
# Add dirs using -L/usrs/local/lib
DEFAULT_LINK="-L/usr/local/lib"
LINK=""
LIBS=""

# Extension of the files that will be compiled
# Change with -e cc
FILE_EXT="cpp"

MAIN_FILE="main.$FILE_EXT"

# Automatic conversion from dos files to unix files
# Disabled by default use -a to enable it
AUTO_UNIX=""
# Colors. Enabled by default, use -C to disable it
COLORS="YES"

# Name of the executable
# Change with -E test
EXEC="main"

# Name of the Makefile
# Change with -M newName
MAKEFILE="Makefile"

# Utility functions

# This fucntion is the core of the script: it recursively search any dependecy
# for every file that must be compiled
function find_dependencies() {
  # We search for include
  is_unix_valid $1
  ERR="$?"
  if [ ! "$ERR" = 0 ]; then
    exit $ERR
  fi
  DEP=`grep "^ *#include" $1 | sed -e 's/^ *#include *[\<"]//g' -e 's/[\>"]*//g'`
  # No newline, better than tr
  #DEP=`echo ${DEP}`
  for I in `echo $DEP`; do
    # basename is because of #include "dir/File.h"
    TMP="`find $SRC_DIR -name $(basename ${I})`"
    # Is the file in the project?
    if [ "$TMP" ]; then
      VALID="`echo $MY_DEP | sed "s#.*${TMP}.*#BAD#g"`"
      # We stop the recursivity because the file have already been checked
      if [ ! "$VALID" = "BAD" ]; then
        MY_DEP="$MY_DEP $TMP"
        find_dependencies $TMP
        ERR="$?"
        if [ ! "$ERR" = 0 ]; then
          exit $ERR
        fi
      fi
    fi
  done
}

# Just the help when -h
ME="$0"
function help() {
  echo "usage: ${ME} [-hDa] [-s src-dir] [-o obj-dir] [-b bin-dir] [-c compiler] [-O \"compiler options\"] [-L link-dirs] [-l lib] [-I include-dir] [-M Makefile-name] [-e file-extension] [-E executable-name]
  -h\tShow this help.
  -D\tSupress the default options for -L,-I and -O
  -a\tAutomatic conversion of file in dos format to unix format. This option uses d

Running without arguments is equivalent to this:
  ${ME} -D -s src -o obj -b bin -c \"xcrun clang++\" -O \"-Wall -Wextra -O2 -std=c++11 -stdlib=libc++\" -Isrc -L/usr/local/lib -e cpp -E main -M Makefile

GitHub repo: https://github.com/posva/configure-script"
}

# Check if the file is unix or dos
function is_unix_valid() {
  if grep -q "
    if [ "$AUTO_UNIX" ]; then
      # Convert the file using tr
      tr -d '\r' < $1 > $1.bak
      # check again
      if grep -q "
        echo -e "${RED}The file $1 has DOS return (^M). The conversion with the -a option failed, please convert it manually.${CLEAN_COLOR}"
        rm -f $1.bak
        exit 2
      else
        # File is valid, let's swap! :D
        echo -e "${BRIGHT_GREEN}File $1 converted from dos to unix correctly.${CLEAN_COLOR}"
        mv -f $1.bak $1
      fi
    else
      echo -e "${RED}The file $1 has DOS return (^M). Convert it with vim, dos2unix, sed, any other tool or use the -a option.${CLEAN_COLOR}"
      exit 2
    fi
  fi
}

# Recognize parameters
while getopts ahCs:o:b:c:DO:L:l:I:M:e:E: opt
do
  case "$opt" in
    (h) help ; exit ;;
    (a) AUTO_UNIX="YES" ;;
    (C) COLORS="" ;;
    (s) SRC_DIR="$OPTARG" ;;
    (b) BIN_DIR="$OPTARG" ;;
    (o) OBJ_DIR="$OPTARG" ;;
    (l) LIBS="$LIBS $OPTARG" ;;
    (L) LINK="$LINK -L$OPTARG" ;;
    (e) FILE_EXT="$OPTARG" ;;
    (E) EXEC="$OPTARG" ;;
    (c) CXX="$OPTARG" ;;
    (I) INCLUDE="$INCLUDE -I$OPTARG" ;;
    (O) OPTIONS="$OPTIONS $OPTARG" ;;
    (D) DEFAULT_OPTIONS=""; DEFAULT_INCLUDE=""; DEFAULT_LINK="" ;;
    (M) MAKEFILE="$OPTARG" ;;
  esac
done

shift $(($OPTIND - 1))

# COLORS!!!!
if [ "$COLORS" ]; then
  RED="\e[00;31m"
  BLUE="\e[01;34m"
  GREEN="\e[00;32m"
  BRIGHT_GREEN="\e[01;32m"
  YELLOW="\e[00;33m"
  CLEAN_COLOR="\e[00m"
fi

# Start to work!

# Find directories and files
FOLDERS=`find $SRC_DIR/* -type d | sed "s/$SRC_DIR/$OBJ_DIR/g"`
FOLDERS=`echo $FOLDERS | tr '\n' ' '`
FILES=`find $SRC_DIR/* -type f -name "*.$FILE_EXT"`
OBJ_FILES="`echo "${FILES}" | sed -e "s#^ *${SRC_DIR}#${OBJ_DIR}#g" -e "s#${FILE_EXT}#o#g"`"
OBJ_FILES=`echo $(echo ${OBJ_FILES})`

# Create a blank Makefile and add some rules
echo -ne "${BLUE}Creating some rules for Makefile..."
echo "# Makefile generated with configure script by Eduardo San Martin Morote
# aka Posva. http://posva.net

CXX := ${CXX}
OPT := ${DEFAULT_OPTIONS} ${OPTIONS} ${DEFAULT_INCLUDE} ${INCLUDE}
LIBS := ${DEFAULT_LINK} ${LIBS}


all : ${BIN_DIR}/${EXEC}

${BIN_DIR}/${EXEC} : ${OBJ_FILES}
	\$(CXX) \$(OPT) \$^ -o "\$@" \$(LIBS)

run : all
	./${BIN_DIR}/${EXEC}

clean :
	rm -f $OBJ_FILES ${BIN_DIR}/${EXEC}
.PHONY : clean

" > $MAKEFILE
echo -e "${GREEN}OK${CLEAN_COLOR}"

echo -en "${BLUE}Creating directories..."
if mkdir -p $OBJ_DIR $BIN_DIR `echo $FOLDERS`; then
  echo -e "${GREEN}OK"
else
  echo -e "${RED}KO"
  exit $1
fi

for F in `echo $FILES`; do
  is_unix_valid $F
  ERR="$?"
  if [ ! "$ERR" = 0 ]; then
    exit $ERR
  fi

  echo -e "${BLUE}Checking dependencies for ${F}...${CLEAN_COLOR}"
  FINAL_DEP=""
  MY_DEP=""
  find_dependencies $F
  ERR="$?"
  if [ ! "$ERR" = 0 ]; then
    exit $ERR
  fi
  ## Supress blank characters
  FINAL_DEP=$(echo `echo $MY_DEP`)
  # add the rule to the Makefile
  echo "`echo $F | sed -e "s#${SRC_DIR}#${OBJ_DIR}#g" -e "s#${FILE_EXT}#o#g"` : ${F} ${FINAL_DEP}
	\$(CXX) \$(OPT) \$< -c -o \$@

" >> $MAKEFILE

  echo -e "${YELLOW}Dependencies: $FINAL_DEP
${GREEN}OK${CLEAN_COLOR}"
done
