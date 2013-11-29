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

# log elapsed time
if man date | grep BSD >/dev/null 2>/dev/null; then
  IS_BSD="YES"
fi
if [ "${IS_BSD}" ]; then
  LOG_START=`date +%s`
else
  LOG_START=`date +%s%N`
fi

# Some variables that can be changed through options
# -c gcc to change this
CXX="xcrun clang++" # Compiler
# -k to change the linker (the linker is used in only one rule of the Makefile)
LINKER="$CXX"

# Language, by default is C/C++
# Changing the Language with -G will change many options, to overwrite
# these you must use the -G before any other argument-option
LANGUAGE="C"

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

# Trying with Linux and OS X gave me different result, though I was using the clang++
# compiler. Therefore I added this option so we can set specifically the options for
# the linking step.
DEFAULT_LINK_OPT="-std=c++11 -stdlib=libc++"
LINK_OPT=""

# Extension of the files that will be compiled
# Change with -e cc
FILE_EXT="cpp"
OBJ_EXT="o"

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

# Almost useless since this script is already wuite verbose
VERBOSE=""

# Utility functions

# Some variables to make the script fucntional not only for C/C++ projects
# This is what should be changed from one language to another
INC_PREP="^ *#include" # Used to catch lines with includes
INC_PREP_BEG="^ *#include *[\\<\"]" # Supress the begining of the line until the name of the included file
INC_PREP_END="[\\>\"].*" # Supress the end of the line leaving only the thing included

# This function is the core of the script: it recursively searches any dependecy
# for a file passed as first argument
function find_dependencies() {
  MY_DEP=""
  find_dependencies_aux $1
}

# Depending on the language the include filename can change
# for instance in C/C++ the you don't need to do anything:
# you etract file.h from #include "file.h" and it's OK
# but in Java you extract file from import com.pack.file;
# and you need to add the .java to have the real filename
INC_FILENAME_BEG=""
INC_FILENAME_END=""

function find_dependencies_aux() {
  # We first look if file isn't dos, otherwise we cannot do the work
  is_unix_valid $1
  ERR="$?"
  if [ ! "$ERR" = 0 ]; then
    exit $ERR
  fi
  # We search for include
  DEP=`grep "$INC_PREP" $1 | sed -e "s/${INC_PREP_BEG}//g" -e "s/${INC_PREP_END}//g"`
  #DEP=`echo ${DEP}`
  for I in `echo $DEP`; do
    # basename is used because of #include "dir/File.h"
    TMP="`find $SRC_DIR -name \"${INC_FILENAME_BEG}$(basename ${I})${INC_FILENAME_END}\"`"
    # Is the file in the project?
    if [ "$TMP" ]; then
      VALID="`echo $MY_DEP | sed "s#.*${TMP}.*#BAD#g"`"
      # We stop the recursivity because the file have already been checked
      if [ ! "$VALID" = "BAD" ]; then
        MY_DEP="$MY_DEP $TMP"
        find_dependencies_aux $TMP
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
  echo "usage: ${ME} [-hfDav] [-G lang] [-s src-dir] [-o obj-dir] [-b bin-dir] [-c compiler] [-k linker] [-O \"compiler options\"] [-L link-dirs] [-l \"-lsome-lib -lother-lib\"] [-I include-dir] [-M Makefile-name] [-e file-extension] [-E executable-name] [-N linker-options]
  -h\tShow this help.
  -D\tSupress the default options for -L, -I, -N and -O.
  -a\tAutomatic conversion of file in dos format to unix format. This option uses d.
  -f\tForces the creation of the Makefile when it already exists without doing any verification.
  -v\tVerbose mode: Show the dependencies for every file

  If you change the compiler with the -c option but not the linker with the -k option, the linker is set to the compiler
  Remember that the -l option requires you to add the -l to any lib as it is shown in the example. However it's the oposite for the -L and -I options which both add the -L and the -I before every argument. Therefore consider using a single -l option and multiple -I and -L options.

Running without arguments is equivalent to this:
  ${ME} -D -s src -o obj -b bin -c \"xcrun clang++\" -O \"-Wall -Wextra -O2 -std=c++11 -stdlib=libc++\" -Isrc -L/usr/local/lib -e cpp -E main -M Makefile -N \"-std=c++11 -stlib=libc++\"

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

# This function swicth between different languages and do the verifications

function change_lang() {
  case "${LANGUAGE}" in
    C)
      SRC_DIR="src"
      OBJ_DIR="obj"
      BIN_DIR="bin"
      CXX="xcrun clang++"
      LINKER="$CXX"
      DEFAULT_OPTIONS="-Wall -Wextra -O2 -std=c++11 -stdlib=libc++"
      OPTIONS=""
      DEFAULT_INCLUDE="-I${SRC_DIR}"
      INCLUDE=""
      DEFAULT_LINK="-L/usr/local/lib"
      LINK=""
      LIBS=""
      DEFAULT_LINK_OPT="-std=c++11 -stdlib=libc++"
      LINK_OPT=""
      FILE_EXT="cpp"
      OBJ_EXT="o"
      EXEC="main"
      INC_PREP="^ *#include"
      INC_PREP_BEG="^ *#include *[\\<\"]"
      INC_PREP_END="[\\>\"].*"
      INC_FILENAME_BEG=""
      INC_FILENAME_END=""
      ;;
    java)
      SRC_DIR="src"
      OBJ_DIR="bin"
      BIN_DIR="bin"
      CXX="javac"
      LINKER="javac"
      DEFAULT_OPTIONS="-g -encoding UTF8"
      OPTIONS=""
      DEFAULT_INCLUDE="-sourcepath ${SRC_DIR}"
      INCLUDE=""
      DEFAULT_LINK="-d ${BIN_DIR}"
      LINK=""
      LIBS=""
      DEFAULT_LINK_OPT=""
      LINK_OPT=""
      FILE_EXT="java"
      OBJ_EXT="class"
      EXEC="App"
      INC_PREP="^ *import"
      INC_PREP_BEG="^ *import  *.*\\."
      INC_PREP_END=";.*"
      INC_FILENAME_BEG=""
      INC_FILENAME_END=".java"
      ;;
    *)
      echo "The language ${LANGUAGE} is not supported (yet). You can ass the support if you want and do a pull request at https://github.com/posva/configure-script . I'll really appreciate it :D"
      exit 1
      ;;
  esac
}

# Recognize parameters
COMPILER_CHANGED=""
LINKER_SET=""
while getopts avfhCs:o:b:c:k:DO:L:l:I:M:e:E:N:G: opt
do
  case "$opt" in
    (h) help ; exit ;;
    (v) VERBOSE="YES" ;;
    (a) AUTO_UNIX="YES" ;;
    (C) COLORS="" ;;
    (s) SRC_DIR="$OPTARG" ;;
    (b) BIN_DIR="$OPTARG" ;;
    (o) OBJ_DIR="$OPTARG" ;;
    (l) LIBS="$LIBS $OPTARG" ;;
    (L) LINK="$LINK -L$OPTARG" ;;
    (e) FILE_EXT="$OPTARG" ;;
    (E) EXEC="$OPTARG" ;;
    (c) CXX="$OPTARG"; COMPILER_CHANGED="YES" ;;
    (k) LINKER="$OPTARG"; LINKER_SET="YES" ;;
    (I) INCLUDE="$INCLUDE -I$OPTARG" ;;
    (O) OPTIONS="$OPTIONS $OPTARG" ;;
    (D) DEFAULT_OPTIONS=""; DEFAULT_INCLUDE=""; DEFAULT_LINK=""; DEFAULT_LINK_OPT="" ;;
    (M) MAKEFILE="$OPTARG" ;;
    (N) LINK_OPT="$OPTARG" ;;
    (G) LANGUAGE="$OPTARG" ; change_lang ; if [ ! "$?" = 0 ]; then exit "$?" ; fi ;;
    (f) FORCE="YES" ;;
  esac
done

shift $(($OPTIND - 1))

# Set the linker in certain condition
if [ "$COMPILER_CHANGED" -a ! "$LINKER_SET" ]; then
  LINKER="$CXX"
fi

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
OBJ_FILES="`echo "${FILES}" | sed -e "s#^ *${SRC_DIR}#${OBJ_DIR}#g" -e "s#${FILE_EXT}#${OBJ_EXT}#g"`"
OBJ_FILES=`echo $(echo ${OBJ_FILES})`

# Check if there's already a Makefile
NEED_UPDATE=""
if [  "$FORCE" = "" -a -f "$MAKEFILE" ] ; then
  echo -e "${BLUE}There's already a file named ${MAKEFILE}. Checking if there's something new in the project (You can use the -f option to automatically avoid this check).${CLEAN_COLOR}"

  # We first check if there is a new file in the project
  for F in `echo $FILES`; do
    OF=`echo "$F" | sed -e "s#${SRC_DIR}#${OBJ_DIR}#g" -e "s#${FILE_EXT}#${OBJ_EXT}#g"`
    if ! grep "$OF" $MAKEFILE 2>/dev/null 1>/dev/null ; then
      NEED_UPDATE="YES"
      echo -e "${RED}${OF} doesn't have a rule. A new ${MAKEFILE} is going to be generated.${CLEAN_COLOR}"
      break
    fi
  done

  # We now check if there's a deleted file in the project
  if [ ! "$NEED_UPDATE" ]; then
    RULES=`grep ".${OBJ_EXT} :" ${MAKEFILE} | sed -e 's# :.*##g' -e "s#\.${OBJ_EXT}#.${FILE_EXT}#g"`
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
    M_LINKER="`grep "^LINKER :=" ${MAKEFILE} | sed 's#LINKER := ##g'`"
    M_OPT="`grep "^OPT :=" ${MAKEFILE} | sed 's#OPT := ##g'`"
    M_LINK_OPT="`grep "^LINK_OPT :=" ${MAKEFILE} | sed 's#LINK_OPT := ##g'`"
    M_LIBS="`grep "^LIBS :=" ${MAKEFILE} | sed 's#LIBS := ##g'`"
    M_EXEC="`grep "^EXEC :=" ${MAKEFILE} | sed 's#EXEC := ##g'`"

    if [ ! "${M_CXX}" = "${CXX}" -o ! "${M_LINKER}" = "${LINKER}" -o ! "${M_OPT}" = "${DEFAULT_OPTIONS} ${OPTIONS} ${DEFAULT_INCLUDE} ${INCLUDE}" -o ! "${M_LIBS}" = "${DEFAULT_LINK} ${LIBS}" -o ! "${M_LINK_OPT}" = "${DEFAULT_LINK_OPT} ${LINK_OPT} ${LINK}" -o ! "${M_EXEC}" = "${EXEC}" ]; then
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
echo -ne "${BLUE}Creating some rules for Makefile...${CLEAN_COLOR}"
echo "# Makefile generated with configure script by Eduardo San Martin Morote
# aka Posva. http://posva.net
# GitHub repo: https://github.com/posva/configure-script
# Please report any bug to i@posva.net

CXX := ${CXX}
LINKER := ${LINKER}
OPT := ${DEFAULT_OPTIONS} ${OPTIONS} ${DEFAULT_INCLUDE} ${INCLUDE}
LINK_OPT := ${DEFAULT_LINK_OPT} ${LINK_OPT} ${LINK}
LIBS := ${DEFAULT_LINK} ${LIBS}
EXEC := ${EXEC}


" > ${MAKEFILE}

case "$LANGUAGE" in
  C)
    echo "
all : ${BIN_DIR}/\$(EXEC)

${BIN_DIR}/\$(EXEC) : ${OBJ_FILES}
	\$(LINKER) \$(LINK_OPT) \$^ -o "\$@" \$(LIBS)

run : all
	./${BIN_DIR}/\$(EXEC)

clean :
	rm -f $OBJ_FILES ${BIN_DIR}/\$(EXEC)
.PHONY : clean

" >> ${MAKEFILE}
    ;;
  java)
    echo "all : ${OBJ_FILES}

run : all
	cd ${BIN_DIR} && java ${EXEC}
.PHONY : run

clean :
	rm -f $OBJ_FILES
.PHONY : clean

" >> ${MAKEFILE}
    ;;
esac

# TODO nest every echo in the case to avoid unused variables

echo -e "${GREEN}OK${CLEAN_COLOR}"

# Create the directories obj and bin
echo -en "${BLUE}Creating directories...${CLEAN_COLOR}"
if mkdir -p $OBJ_DIR $BIN_DIR `echo $FOLDERS`; then
  echo -e "${GREEN}OK${CLEAN_COLOR}"
else
  echo -e "${RED}KO${CLEAN_COLOR}"
  exit $1
fi

# Find every dependecy for each file
for F in `echo $FILES`; do
  is_unix_valid $F
  ERR="$?"
  if [ ! "$ERR" = 0 ]; then
    exit $ERR
  fi

  echo -ne "${BLUE}Checking dependencies for ${F}...${CLEAN_COLOR}"

  find_dependencies $F
  ERR="$?"
  if [ ! "$ERR" = 0 ]; then
    exit $ERR
  fi
  ## Supress blank characters
  FINAL_DEP=$(echo `echo $MY_DEP`)
  # add the rule to the Makefile
  case "$LANGUAGE" in
    C)
      echo "`echo $F | sed -e "s#${SRC_DIR}#${OBJ_DIR}#g" -e "s#${FILE_EXT}#${OBJ_EXT}#g"` : ${F} ${FINAL_DEP}
	\$(CXX) \$(OPT) \$< -c -o \$@

" >> $MAKEFILE
      ;;
    java)
      echo "`echo $F | sed -e "s#${SRC_DIR}#${OBJ_DIR}#g" -e "s#${FILE_EXT}#${OBJ_EXT}#g"` : ${F} ${FINAL_DEP}
	\$(CXX) \$(OPT) \$(LIBS) \$<

" >> $MAKEFILE
      ;;
  esac

  echo -e "${GREEN}OK${CLEAN_COLOR}"
  if [ "$VERBOSE" ]; then
    echo -e "${YELLOW}Dependencies: $FINAL_DEP${CLEAN_COLOR}"
  fi
done

# log the elapsed time
# BSD date don't have nanoseconds
if [ "${IS_BSD}" ]; then
  LOG_END=`date +%s`
  ELAPSED=$(( $LOG_END - $LOG_START ))
else
  LOG_END=`date +%s%N`
  ELAPSED=`echo "scale=8; ($LOG_END - $LOG_START) / 1000000000" | bc`
fi
echo -e "${YELLOW}Makefile generated in ${ELAPSED} seconds.${CLEAN_COLOR}"

