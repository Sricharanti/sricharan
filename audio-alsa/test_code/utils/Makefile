#===============================================================================
#             Texas Instruments OMAP(TM) Platform Software
#  (c) Copyright Texas Instruments, Incorporated.  All Rights Reserved.
#
#  Use of this software is controlled by the terms and conditions found
#  in the license agreement under which this software has been supplied.
#===============================================================================

SUBDIRS := omap-audio-tool abe_trace

.PHONY:	$(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	make ARCH=arm -C $@

install:
	cp -vf omap-audio-tool/audio-tool ../bin/
	cp -vf abe_trace/abe_trace ../bin/

clean:
	make -C omap-audio-tool clean
	make -C abe_trace clean
