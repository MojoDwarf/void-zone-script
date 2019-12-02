#!/bin/sh

#  void-zones-update.sh
#  void-zones-tools
#
# Shell Script for updating the void zones list by downloading from pre-defined hosts file providers
#
# Created by Dr. Rolf Jansen on 2016-11-16.
# Copyright (c) 2016, projectworld.net. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS
# OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER
# OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
# THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Original version https://github.com/cyclaero/void-zones-tools/blob/master/void-zones-update.sh
# Includes lists added by Privacywonk https://github.com/Privacywonk/void-zones-tools

### verify the path to the fetch utility
# TODO: think about replacing with a simple eval usage
if [ -e "/usr/bin/fetch" ]; then
   FETCH="/usr/bin/fetch"
elif [ -e "/usr/local/bin/fetch" ]; then
   FETCH="/usr/local/bin/fetch"
elif [ -e "/opt/local/bin/fetch" ]; then
   FETCH="/opt/local/bin/fetch"
else
   echo "No fetch utility can be found on the system -- Stopping."
   echo "On Mac OS X, execute either 'sudo port install fetch' or install"
   echo "fetch from source into '/usr/local/bin', and then try again."
   exit 1
fi


### quiet mode
QUIET=""
while [ "$#" -gt 0  ]
do
    case "$1" in
        -q)
            shift
            FETCH="$FETCH -q"
            QUIET="> /dev/null"
            ;;
        *)
            echo "unknown option '$1'"
            exit 1
            ;;
    esac
    shift
done


### Storage location of the dowloaded void hosts lists
ZONES_DIR="/usr/local/etc/void-zones"
if [ ! -d "$ZONES_DIR" ]; then
   mkdir -p "$ZONES_DIR"
fi
if [ ! -f "$ZONES_DIR/my_void_hosts.txt" ]; then
   echo "# white list"          > "$ZONES_DIR/my_void_hosts.txt"
   echo "1.1.1.1 my.white.dom" >> "$ZONES_DIR/my_void_hosts.txt"
   echo ""                     >> "$ZONES_DIR/my_void_hosts.txt"
   echo "# black list"         >> "$ZONES_DIR/my_void_hosts.txt"
   echo "0.0.0.0 my.black.dom" >> "$ZONES_DIR/my_void_hosts.txt"
fi


### Void Lists, lists could be from a separate version control, etc
LIST_DIR="/usr/local/etc/void-zones.d"
if [ ! -d "$LIST_DIR" ]; then
   mkdir -p "$LIST_DIR"
fi


### Updating the void zones
for LIST in `ls $LIST_DIR`
do
    URL=`cat "$LIST_DIR/$LIST"`
    $FETCH -o "$ZONES_DIR/$LIST" $URL

    if [ ! -f "$ZONES_DIR/$LIST" ]; then
        echo "# No hosts found: $URL" > "$ZONES_DIR/$LIST"
    fi
done


### Build unbound zone file
ZONES_TEMP="/tmp/local-void.zones"
ZONES_FILE="/var/unbound/local-void.zones"

eval hosts2zones $ZONES_TEMP `ls $ZONES_DIR/*.txt` $QUIET && eval mv $ZONES_TEMP $ZONES_FILE

