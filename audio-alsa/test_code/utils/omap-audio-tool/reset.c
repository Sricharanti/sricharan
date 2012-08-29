/*
 * reset.c
 *
 * Copyright (C) 2012 Texas Instruments Incorporated - http://www.ti.com/
 *
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *
 *    Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *    Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the
 *    distribution.
 *
 *    Neither the name of Texas Instruments Incorporated nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 *  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 *  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 *  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 *  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 *  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 *  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include <errno.h>
#include <stdio.h>
#include <tinyalsa/asoundlib.h>

#include "config.h"
#include "alsa-control.h"

int reset_main(const struct audio_tool_config *config, int argc, char **argv)
{
	struct mixer *mixer;
	struct mixer_ctl *ctl;
	int card = config->card;
	int cards = ah_card_count();
	unsigned int num_ctls;
	int i, j;

	if (card < 0 || card >= cards) {
		fprintf(stderr, "Error: card %d does not exist\n", card);
		return -EINVAL;
	}

	mixer = mixer_open(card);
	if (!mixer) {
		fprintf(stderr, "Error: could not open mixer device (%s)\n",
			strerror(errno));
		return -ENODEV;
	}

	num_ctls = mixer_get_num_ctls(mixer);
	for (i = 0; i < num_ctls; i++) {
		ctl = mixer_get_ctl(mixer, i);
		switch (mixer_ctl_get_type(ctl)) {
		case MIXER_CTL_TYPE_BOOL:
		case MIXER_CTL_TYPE_INT:
			for (j = 0; j < mixer_ctl_get_num_values(ctl); j++)
				mixer_ctl_set_value(ctl, j, 0);
			break;
		case MIXER_CTL_TYPE_ENUM:
			mixer_ctl_set_enum_by_string(ctl, "Off");
			break;
		default:
			break;
		}
	}

	mixer_close(mixer);

	return 0;
}
