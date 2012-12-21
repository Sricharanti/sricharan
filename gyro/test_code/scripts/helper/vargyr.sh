#!/bin/sh
#passes if each axis reports status at one time in every two "Report Sync" 

export TYPENO=2
export TYPEADJECTIVE=Relative
export DIGITAL_COMPASS_CODEX=3
export DIGITAL_COMPASS_CODEY=4
export DIGITAL_COMPASS_CODEZ=5
export DIGITAL_COMPASS_TEXTX=?
export DIGITAL_COMPASS_TEXTY=?
export DIGITAL_COMPASS_TEXTZ=?
VARMAX=169

#Event: time 222.188385, type 2 (Absolute), code 16 (Hat0X), value 356
#Event: time 222.188385, type 2 (Absolute), code 17 (Hat0Y), value 518
#Event: time 222.188416, type 2 (Absolute), code 10 (Brake), value -71
#Event: time 222.188556, -------------- Report Sync ------------

# $1 COUNTX
# $2 TOTALX
# $3 TOTALX2
var ()
{ # variance = ( $1 * $3 - $2 * $2 ) / ( $1 * ( $1 -1 ))
  local tmpa=`expr $1 \* $3`
  local tmpb=`expr $2 \* $2`
  local tmpc=`expr $tmpa - $tmpb`
  local tmpa=`expr $1 - 1`
  local tmpb=`expr $1 \* $tmpa`
  return `expr $tmpc \/ $tmpb`
}

# $1 variableSuffix
# $2 value
addv ()
{
    #COUNTX=`expr "${COUNTX}" + 1`
    local scountx=\$COUNT"$1"
    local countx=COUNT"$1"
    local valcountx=`eval "expr \"$scountx\" "`
    eval "$countx=`expr \"$valcountx\" + \"1\"`"

    #TOTALX=`expr "${TOTALX}" + "$2"`
    local stotalx=\$TOTAL"$1"
    local totalx=TOTAL"$1"
    local valtotalx=`eval "expr \"$stotalx\" "`
    eval "$totalx=`expr \"$valtotalx\" + \"$2\"`"

    local square=`expr "$2" \* "$2"`

    #TOTALX2=`expr "${TOTALX2}" + "${SQUARE}"`
    local stotalx2=\$TOTAL"$1"2
    local totalx2=TOTAL"$1"2
    local valtotalx2=`eval "expr \"$stotalx2\" "`
    eval "$totalx2=`expr \"$valtotalx2\" + \"$square\"`"

    local sminx=\$MIN"$1"
    local minx=MIN"$1"
    local valminx=`eval "expr \"$sminx\" "`
    if [ "$2" -lt "$valminx" ]; then
      eval "$minx=$2"
    fi

    local smaxx=\$MAX"$1"
    local maxx=MAX"$1"
    local valmaxx=`eval "expr \"$smaxx\" "`
    if [ "$2" -gt "$valmaxx" ]; then
      eval "$maxx=$2"
    fi
}

MINX=8000
MAXX=-8000
MISSINGX=0
COUNTX=0
TOTALX=0
TOTALX2=0
MINY=8000
MAXY=-8000
MISSINGY=0
COUNTY=0
TOTALY=0
TOTALY2=0
MINZ=8000
MAXZ=-8000
MISSINGZ=0
COUNTZ=0
TOTALZ=0
TOTALZ2=0

while read line
do
  echo "${line}"|grep -q "type $TYPENO ($TYPEADJECTIVE), code $DIGITAL_COMPASS_CODEX ($DIGITAL_COMPASS_TEXTX), value"
  HATOXR=`echo $?`
  echo "${line}"|grep -q "type $TYPENO ($TYPEADJECTIVE), code $DIGITAL_COMPASS_CODEY ($DIGITAL_COMPASS_TEXTY), value"
  HATOYR=`echo $?`
  echo "${line}"|grep -q "type $TYPENO ($TYPEADJECTIVE), code $DIGITAL_COMPASS_CODEZ ($DIGITAL_COMPASS_TEXTZ), value"
  HATOZR=`echo $?`
  echo "${line}"|grep -q -e '-------------- Report Sync ------------'
  RSYNCR=`echo $?`

  VALUE=`echo "${line}"|cut -d " " -f 11`
  if [ "0" -eq "$HATOXR" ]; then
    LASTX=$VALUE
    MISSINGX=1
    addv X $LASTX
  elif [ "0" -eq "$HATOYR" ]; then
    LASTY=$VALUE
    MISSINGY=1
    addv Y $LASTY
  elif [ "0" -eq "$HATOZR" ]; then
    LASTZ=$VALUE
    MISSINGZ=1
    addv Z $LASTZ
  elif [ "0" -eq "$RSYNCR" ]; then
    if [ "0" -eq "$MISSINGX" ]; then
      if [ -n "$LASTX" ]; then
        addv X $LASTX
      fi
    fi
    if [ "0" -eq "$MISSINGY" ]; then
      if [ -n "$LASTY" ]; then
        addv Y $LASTY
      fi
    fi
    if [ "0" -eq "$MISSINGZ" ]; then
      if [ -n "$LASTZ" ]; then
        addv Z $LASTZ
      fi
    fi

    #echo $COUNTX $TOTALX $TOTALX2 ":" $COUNTY $TOTALY $TOTALY2 ":" $COUNTZ $TOTALZ $TOTALZ2
    MISSINGX=0
    MISSINGY=0
    MISSINGZ=0
  fi
done

RV=0
NRESPONSE=0
TRESPONSE=`expr "$COUNTX" + "$COUNTY"`
TRESPONSE=`expr "$TRESPONSE" + "$COUNTZ"`


if [ "$COUNTX" -gt "0" ]; then
  NRESPONSE=`expr "$NRESPONSE" + 1`
fi
if [ "$COUNTY" -gt "0" ]; then
  NRESPONSE=`expr "$NRESPONSE" + 1`
fi
if [ "$COUNTZ" -gt "0" ]; then
  NRESPONSE=`expr "$NRESPONSE" + 1`
fi

if [ "$NRESPONSE" -lt "1" ]; then
  echo 'NO valid response - terminating.'
  exit 4
fi

NRESPONSE2=`expr "$NRESPONSE" \* 2`
HRESPONSE=`expr "$TRESPONSE" \/ "$NRESPONSE2"`
#HRESPONSE = half avg # counts per axis

if [ "$COUNTX" -gt "0" ]; then
  AVGX=`expr $TOTALX / $COUNTX`
  var $COUNTX $TOTALX $TOTALX2
  VARX=$?
  echo "AVGX=" $AVGX "VARX=" $VARX $COUNTX $TOTALX $TOTALX2 $MINX $MAXX
  #if [ "$VARX" -gt "$VARMAX" ]; then
  #  RV=`expr "$RV" + 1`
  #fi
  if [ "$COUNTX" -lt "$HRESPONSE" ]; then
    RV=`expr "$RV" + 2`
  fi
fi
if [ "$COUNTY" -gt "0" ]; then
  AVGY=`expr $TOTALY / $COUNTY`
  var $COUNTY $TOTALY $TOTALY2
  VARY=$?
  echo "AVGY=" $AVGY "VARY=" $VARY $COUNTY $TOTALY $TOTALY2 $MINY $MAXY
  #if [ "$VARY" -gt "$VARMAX" ]; then
  #  RV=`expr "$RV" + 1`
  #fi
  if [ "$COUNTY" -lt "$HRESPONSE" ]; then
    RV=`expr "$RV" + 2`
  fi
fi
if [ "$COUNTZ" -gt "0" ]; then
  AVGZ=`expr $TOTALZ / $COUNTZ`
  var $COUNTZ $TOTALZ $TOTALZ2
  VARZ=$?
  echo "AVGZ=" $AVGZ "VARZ=" $VARZ $COUNTZ $TOTALZ $TOTALZ2 $MINZ $MAXZ
  #if [ "$VARZ" -gt "$VARMAX" ]; then
  #  RV=`expr "$RV" + 1`
  #fi
  if [ "$COUNTZ" -lt "$HRESPONSE" ]; then
    RV=`expr "$RV" + 2`
  fi
fi
exit $RV

