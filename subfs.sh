#!/bin/bash
# 
# Manager to create and resize reiserfs sub-filesystems, which are stored in 
# sparse files.
# 
# -----------------------------------------------------------------------------
#
# Copyright (c) 2013, Johannes Buchner
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
#
#    Redistributions of source code must retain the above copyright notice, 
#      this list of conditions and the following disclaimer.
#    Redistributions in binary form must reproduce the above copyright notice, 
#      this list of conditions and the following disclaimer in the 
#      documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
# 
# -----------------------------------------------------------------------------

function usage() {
	echo "SYNAPSIS: $0 <mountpoint> <command> <size>"
	echo
	echo "(C) Johannes Buchner, 2013"
	echo ""
	echo ""
	echo "This script creates and manages a reiser filesystem and mounts it at mountpoint"
	echo "The sparse data file used will be stored at <mountpoint>.fs"
	echo "You will need to run this script as root (for mounting)"
	echo ""
	echo "commands:"
	echo ""
	echo "	create <size>: Creates a new filesystem of size <size>."
	echo "	               Example: create 1G "
	echo ""
	echo "	expand <size>: Set the new size to <size>, expanding the file system."
	echo "	               Example: expand 2G "
	echo "	               Example: expand +1G "
	echo ""
	echo "	shrink <size>: Set the new size to <size>, shrinking the file system."
	echo "	               Example: shrink 1G "
	echo "	               Example: shrink -1G "
	echo ""
	echo "	destroy      : Removes the filesystem destroying all data."
	echo ""
}

NAME=$1
CMD=$2
SIZE=$3

if mountpoint -q $NAME; then
	echo 'unmounting first'
	umount $NAME.fs
	if [ $? -eq 2 ]; then
		echo 'unmounting failed'
		exit 2
	fi
fi

if [ "$NAME" = "--help" ] || [ "$NAME" = "-h" ] || [ "$NAME" = "" ]; then
	CMD=""
fi

if [ "$CMD" = "create" ]; then
	truncate $NAME.fs -s$SIZE || exit 4
	mkreiserfs -f $NAME.fs || exit 2
elif [ "$CMD" = "expand" ]; then
	truncate $NAME.fs -s$SIZE || exit 4
	resize_reiserfs -s $SIZE $NAME.fs || exit 5
elif [ "$CMD" = "shrink" ]; then
	resize_reiserfs -s $SIZE $NAME.fs || exit 5
	truncate $NAME.fs -s$SIZE || exit 4
elif [ "$CMD" = "destroy" ]; then
	rm -i $NAME.fs || exit 6
	rmdir $NAME || exit 7
elif [ "$CMD" = "umount" ]; then
	rmdir $NAME || exit 7
elif [ "$CMD" = "mount" ]; then
	true
else
	usage
	exit -1
fi

if [ -e $NAME.fs ]; then
	echo "mounting ..."
	mkdir -p $NAME || exit 100
	mount -o loop $NAME.fs $NAME || exit 101
	echo
	echo " ===== stats for $NAME.fs mounted on $NAME: ===== "
	echo
	echo "Claimed space:" $(du -h --apparent-size $NAME.fs)
	echo "Used space on disk:" $(du -h $NAME.fs)
	echo "Free space:" $(df -ml $NAME|tail -n1|awk '{print $4, " of ", $2, "M free (", $5, " used)"}')
fi


