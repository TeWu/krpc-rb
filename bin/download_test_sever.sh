#!/bin/bash

DEFAULT_VERSION="0.4.0-106-g35176f6"

OUT_DIR="TestServer"
VERSION_FILE="VERSION.txt"


function main {
  trap exit ERR
  local QUIET_IF_EXISTS=false
  if [ "$1" = "--quiet-if-exists" ]; then
    QUIET_IF_EXISTS=true
    shift
  fi
  local VERSION=${1:-$DEFAULT_VERSION}

  cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Change to PWD of this script

  if [ -d $OUT_DIR ]; then
    if [ ! -f "$OUT_DIR/$VERSION_FILE" ]; then
      (>&2 echo "ERROR: File $PWD/$OUT_DIR/$VERSION_FILE doesn't exist. Please remove $PWD/$OUT_DIR directory and try again.")
      exit 1
    else
      CURRENT_VERSION=`cat "$OUT_DIR/$VERSION_FILE"`
      if [ $CURRENT_VERSION = $VERSION ]; then
        if [ "$QUIET_IF_EXISTS" = false ]; then
          echo "TestServer $VERSION is already downloaded"
        fi
        exit 0
      fi
      BACKUP_DIR="${OUT_DIR}_$CURRENT_VERSION"
      if [ -d $BACKUP_DIR ]; then
        (>&2 echo "ERROR: Directory $PWD/$BACKUP_DIR already exists. Can't backup $PWD/$OUT_DIR directory to $PWD/$BACKUP_DIR.")
        exit 2
      fi
      echo "Backing up TestServer $CURRENT_VERSION to $PWD/$BACKUP_DIR"
      mv $OUT_DIR $BACKUP_DIR
    fi
  fi

  RESTORE_DIR="${OUT_DIR}_$VERSION"
  if [ -d $RESTORE_DIR ]; then
    echo "Restoring backed up version of TestServer $VERSION from $PWD/$RESTORE_DIR"
    mv $RESTORE_DIR $OUT_DIR
    echo "TestServer $VERSION restored successfully"
  else
    local URL_PREFIX="https://github.com/TeWu/krpc-TestServer/releases/download/$VERSION"
    local ARCHIVE_FILE="kRPC_TestServer_$VERSION.7z"
    local SUM_FILE="kRPC_TestServer_$VERSION.7z.sha1"

    echo "Downloading TestServer $VERSION"
    trap on_err_downloading ERR
    wget --read-timeout=80 --waitretry=30 -t 3 --output-document $ARCHIVE_FILE "$URL_PREFIX/$ARCHIVE_FILE"
    wget --read-timeout=80 --waitretry=30 -t 3 --output-document $SUM_FILE "$URL_PREFIX/$SUM_FILE"
    sha1sum --check $SUM_FILE
    trap exit ERR
    7z x -o$OUT_DIR $ARCHIVE_FILE
    rm $SUM_FILE $ARCHIVE_FILE
    echo "TestServer $VERSION downloaded successfully"
  fi
}

function on_err_downloading {
  printf "\nHINT: If this script has problem downloading TestServer, the reason may be that TestServer files have been moved to different location. If this is the case, then you can try to determine from which location TestServer files are downloaded in the most recent commit in this git repository (e.g. master branch), and manually download TestServer files from that location. Remember that this script would download version $VERSION of TestServer, and you should preferably get this version - but you can use different version, if it makes specs to pass.\n"
  exit 3
}

main $@

