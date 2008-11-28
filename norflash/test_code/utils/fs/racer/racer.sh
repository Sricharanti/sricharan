#!/bin/bash
################################################################################
##                                                                            ##
## Copyright (c) Dan Carpenter., 2004                                         ##
##                                                                            ##
## This program is free software;  you can redistribute it and#or modify      ##
## it under the terms of the GNU General Public License as published by       ##
## the Free Software Foundation; either version 2 of the License, or          ##
## (at your option) any later version.                                        ##
##                                                                            ##
## This program is distributed in the hope that it will be useful, but        ##
## WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY ##
## or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License   ##
## for more details.                                                          ##
##                                                                            ##
## You should have received a copy of the GNU General Public License          ##
## along with this program;  if not, write to the Free Software               ##
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA    ##
##                                                                            ##
################################################################################

## DESCRIPTION:
## This test creates 20 files (0 thru 19) and then shuffles them around,
## deletes, and recreates them as fast as possible.  This is all done in
## an effort to test for race conditions in the filesystem code. This test
## runs until killed or Ctrl-C'd.  It is suggested that it run overnight
## with preempt turned on to make the system more sensitive to race
## conditions.

#-----------------------------------------------------------------------
# Initialize local variables
#-----------------------------------------------------------------------
TCbin=${TCbin:=`pwd`}
TCtmp=${TCtmp:=/tmp/$TC$$}
export PATH=$PATH:$TCbin:.$TCbin/.$TCbin/.$TCbin/bin
export TCID=$TC
export TST_TOTAL=1
export TST_COUNT=1
TARGET_DIR=$1

if [ ! -d "$TARGET_DIR" ]; then
	tst_resm TBROK "no Target dir: $TARGET_DIR"
	exit 1
fi
cd $TARGET_DIR

MAX_FILES=20
CLEAR_SECS=30
DIR="race"

[ -e $DIR ] || mkdir $DIR
$TCbin/file_create.sh $DIR $MAX_FILES &
$TCbin/file_create.sh $DIR $MAX_FILES &
$TCbin/file_create.sh $DIR $MAX_FILES &

$TCbin/dir_create.sh $DIR $MAX_FILES &
$TCbin/dir_create.sh $DIR $MAX_FILES &
$TCbin/dir_create.sh $DIR $MAX_FILES &

$TCbin/file_rename.sh $DIR $MAX_FILES &
$TCbin/file_rename.sh $DIR $MAX_FILES &
$TCbin/file_rename.sh $DIR $MAX_FILES &

$TCbin/file_link.sh $DIR $MAX_FILES &
$TCbin/file_link.sh $DIR $MAX_FILES &
$TCbin/file_link.sh $DIR $MAX_FILES &

$TCbin/file_symlink.sh $DIR $MAX_FILES &
$TCbin/file_symlink.sh $DIR $MAX_FILES &
$TCbin/file_symlink.sh $DIR $MAX_FILES &

$TCbin/file_concat.sh $DIR $MAX_FILES &
$TCbin/file_concat.sh $DIR $MAX_FILES &
$TCbin/file_concat.sh $DIR $MAX_FILES &

$TCbin/file_list.sh $DIR &
$TCbin/file_list.sh $DIR &
$TCbin/file_list.sh $DIR &

$TCbin/file_rm.sh $DIR $MAX_FILES &
$TCbin/file_rm.sh $DIR $MAX_FILES &
$TCbin/file_rm.sh $DIR $MAX_FILES &

echo "CTRL-C to exit"
trap "
    echo \"Cleaning up\" 
    killall file_create.sh 
    killall dir_create.sh
    killall file_rm.sh 
    killall file_rename.sh 
    killall file_link.sh 
    killall file_symlink.sh 
    killall file_list.sh 
    killall file_concat.sh
    exit 0
" 2

while /bin/true ; do
    read tmp
done

