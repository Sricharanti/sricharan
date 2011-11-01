#!/bin/bash

#
#  Android Sqlite3 Database handler
#
#  Copyright (c) 2011 Texas Instruments
#
#  Author: Leed Aguilar <leed.aguilar@ti.com>
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2 of the
#  License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#  USA
#

# =============================================================================
# Local Variables
# =============================================================================

operation=$1
database=$2
param=$3
paramValue=$4
storeInfo=$TMPFILE

if [ $database = "system" ]; then
	dbName="/data/data/com.android.providers.settings/databases/settings.db"
	dbType="system"
else
	echo "Only System Database is implemented"
	exit 1
fi


# =============================================================================
# Functions
# =============================================================================

# Display the script usage
# @ Function: generalUsage
# @ parameters: None
# @ Return: Error flag value
usage() {
cat <<-EOF >&1

	###################### handlerAndroidSqlite3.sh ######################"

	SCRIPT USAGE:

	    handlerAndroidSqlite3.sh [OPERATION] {OPTIONS}

	    Where [OPERATION] can be:
	    A) set
	    B) read
	    C) verify
	    D) compare

	    A) To perform a set task do the following:

	       Try - handlerAndroidSqlite3.sh set {database} {param} {value}

	       Where:
	       @ database = "system", "secure", "bookmarks"
	       @ param    = database parameter name
	       @ value    = new parameter value

	    B) To perform a read task do the following:

	       Try - handlerAndroidSqlite3.sh read {database} {param}

	       Where:
	       @ database = "system", "secure", "bookmarks"
	       @ param    = database parameter name

	    C) To perform a compare operations do the following:

	       Try - handlerAndroidPM.sh compare {database} {param} {value}

	       Where:
	       @ database = "system", "secure", "bookmarks"
	       @ param    = database parameter name
	       @ value    = value to compare


	###################### handlerAndroidSqlite3.sh ######################"

	EOF
	handlerError.sh "log" "1" "halt" "handlerAndroidSqlite3"
	exit 1
}

# Prints a message with a specific format
# @ Function: showInfo
# @ Parameters: <message to display>
# @ Return: None
showInfo() {
	message=$1
	echo "[ handlerAndroidSqlite3 ] $message"
}

# =============================================================================
# Main
# =============================================================================

handlerError.sh "test"
if [ $? -eq 1 ]; then
	exit 1
fi

#TODO: verify script usage

if [ $operation = "read" ]; then

	echo -e ".output $storeInfo\n.dump\n.exit" | sqlite3 $dbName
	val=`grep -r "$param" $storeInfo  | awk '{print$4}' | cut -d"'" -f4`
	# delete tmp file
	rm $storeInfo
	echo "$val"

elif [ $operation = "set" ]; then

	currentVal=`handlerAndroidSqlite3.sh read $database $param`
	showInfo "Current value of $param is $currentVal"
	if [ "$currentVal" = "$paramValue" ]; then
		showInfo "The desired parameter value is already set"
		exit 0
	fi
	sqlite3 $dbName "insert into $dbType values(?,'$param', '$paramValue');"
	showInfo "Restarting Android to populate the new value(s)"
	stop
	sleep 1
	start
	# Verify if Android is ready
	is_android_ready.sh
	if [ $? -eq 1 ]; then
		# Since this is a configuration script, propagate the error
		handlerError.sh "log" "1" "halt" "handlerAndroidSqlite3"
		showInfo "FATAL: it seems Android is not starting"
		exit 1
	fi
	# Verify the value was properly set
	handlerAndroidSqlite3.sh compare $database $param $paramValue
	if [ $? -eq 1 ]; then
		handlerError.sh "log" "1" "halt" "handlerAndroidSqlite3"
		exit 1		
	fi

elif [ $operation = "compare" ]; then
	showInfo "Expected parameter value: $param --> $paramValue"
	currentVal=`handlerAndroidSqlite3.sh read $database $param`
	showInfo "Reading current parameter value: $param --> $currentVal"
	if [ "$currentVal" != "$paramValue" ]; then
		showInfo "ERROR: parameter value does not match"
		# Do not propagate the error this time
		exit 1
	else
		showInfo "PASS: comparison suceeded"
	fi
else
	usage
fi

exit 0

# End of file
