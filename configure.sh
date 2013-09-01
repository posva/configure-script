#! /bin/bash
# If the colors doesn't work under OSX, get a newer version of bash and use that one
# You can also use zsh or disable color (WHY?!) with the -C option

# Configure script that generates a Makefile for a project located at a
# directory. This script doesn't check for compilers or anything as GNU
# Developers Tools does, so use at your own risk.

# To report a bug contact me at i@posva.net
# Written by Eduardo San Martin Morote aka Posva
# http://posva.net
# https://github.com/posva/configure-script

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
# Remember you can use it this way too:
# -l "-lGL -lBox2D"
# Add dirs using -L/usrs/local/lib
# Don't add any -L here
DEFAULT_LINK="-L/usr/local/lib"
LINK=""
LIBS=""

# Extension of the files that will be compiled
# Change with -e cc
FILE_EXT="cpp"

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

# This fucntion is the core of the script: it recursively searches any dependecy
# for a file passed as first argument
function find_dependencies() {
  # We first look if file isn't dos, otherwise we cannot do the work
  is_unix_valid $1
  ERR="$?"
  if [ ! "$ERR" = 0 ]; then
    exit $ERR
  fi
  # We search for include
  DEP=`grep "^ *#include" $1 | sed -e 's/^ *#include *[\<"]//g' -e 's/[\>"].*//g'`
  #DEP=`echo ${DEP}`
  for I in `echo $DEP`; do
    # basename is used because of #include "dir/File.h"
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
  echo "usage: ${ME} [-hfDa] [-s src-dir] [-o obj-dir] [-b bin-dir] [-c compiler] [-O \"compiler options\"] [-L link-dirs] [-l \"-lsome-lib -lother-lib\"] [-I include-dir] [-M Makefile-name] [-e file-extension] [-E executable-name]
  -h\tShow this help.
  -D\tSupress the default options for -L,-I and -O.
  -a\tAutomatic conversion of file in dos format to unix format. This option uses d.
  -f\tForces the creation of the Makefile when it already exists without doing any verification.

  Remember that the -l option requires you to add the -l to any lib as it is shown in the example. However it's the oposite for the -L and -I options which both add the -L and the -I before every argument. Therefore consider using a single -l option and multiple -I and -L options.

Running without arguments is equivalent to this:
  ${ME} -D -s src -o obj -b bin -c \"xcrun clang++\" -O \"-Wall -Wextra -O2 -std=c++11 -stdlib=libc++\" -Isrc -L/usr/local/lib -e cpp -E main -M Makefile

GitHub repo: https://github.com/posva/configure-script"
}

# Check if the file is unix or dos and convert it if
# the used asked for it with -a
function is_unix_valid() {
  if grep -q "" $1 ; then
    if [ "$AUTO_UNIX" ]; then
      # Convert the file using tr
      tr -d '\r' < $1 > $1.bak
      # check again
      if grep -q "" $1.bak ; then
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
while getopts afhCs:o:b:c:DO:L:l:I:M:e:E: opt
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
    (f) FORCE="YES" ;;
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

# Check if there's already a Makefile
NEED_UPDATE=""
if [  "$FORCE" = "" -a -f "$MAKEFILE" ] ; then
  echo -e "${BLUE}There's already a file named ${MAKEFILE}. Checking if there's something new in the project (You can use the -f option to automatically avoid this check).${CLEAN_COLOR}"

  # We first check if there is a new file in the project
  for F in `echo $FILES`; do
    OF=`echo "$F" | sed -e "s#${SRC_DIR}#${OBJ_DIR}#g" -e "s#${FILE_EXT}#o#g"`
    if ! grep "$OF" $MAKEFILE 2>/dev/null 1>/dev/null ; then
      NEED_UPDATE="YES"
      echo -e "${RED}${OF} doesn't have a rule. A new ${MAKEFILE} is going to be generated.${CLEAN_COLOR}"
      break
    fi
  done

  # We now check if there's a deleted file in the project
  if [ ! "$NEED_UPDATE" ]; then
    RULES=`grep ".o :" ${MAKEFILE} | sed -e 's# :.*##g' -e "s#\.o#.${FILE_EXT}#g"`
    for F in `echo $RULES`; do
      if [ ! "`find ${SRC_DIR} -name $(basename $F)`" ]; then
        NEED_UPDATE="YES"
        echo -e "${RED}`basename $F` doesn't exist anymore but there is a rule in the Makefile.${CLEAN_COLOR}"
        break
      fi
    done
  fi

  # Verify some variables such as compilers, options, include dirs, etc
  if [ ! "$NEED_UPDATE" ]; then
    M_CXX="`grep "^CXX :=" ${MAKEFILE} | sed 's#CXX := ##g'`"
    M_OPT="`grep "^OPT :=" ${MAKEFILE} | sed 's#OPT := ##g'`"
    M_LIBS="`grep "^LIBS :=" ${MAKEFILE} | sed 's#LIBS := ##g'`"

    if [ ! "${M_CXX}" = "${CXX}" -o ! "${M_OPT}" = "${DEFAULT_OPTIONS} ${OPTIONS} ${DEFAULT_INCLUDE} ${INCLUDE}" -o ! "${M_LIBS}" = "${DEFAULT_LINK} ${LIBS}" ]; then
      NEED_UPDATE="YES"
      echo -e "${RED}Some options changed, the Makefile must be generated again.${CLEAN_COLOR}"
    fi
  fi

  # We need to do a verification of the dependencies for each rule
  # TODO Add the real verification isntead of a Warning message
  if [ ! "$NEED_UPDATE" ]; then
    echo -e "${YELLOW}It seems the $MAKEFILE is up-to-date, though not a single dependency has been checked. Therefore if you have added new dependencies (#include) to any of the files in the project consider using the -f option to regenerate it.${CLEAN_COLOR}"
    exit
  fi
fi

# Create a blank Makefile and add some rules
echo -ne "${BLUE}Creating some rules for Makefile..."
echo "# Makefile generated with configure script by Eduardo San Martin Morote
# aka Posva. http://posva.net
# GitHub repo: https://github.com/posva/configure-script
# Please report any bug to i@posva.net

CXX := ${CXX}
OPT := ${DEFAULT_OPTIONS} ${OPTIONS} ${DEFAULT_INCLUDE} ${INCLUDE}
LINK_OPT :=
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
	\$(CXX) \$(LINK_OPT) \$< -c -o \$@

" >> $MAKEFILE

  echo -e "${YELLOW}Dependencies: $FINAL_DEP
${GREEN}OK${CLEAN_COLOR}"
done

