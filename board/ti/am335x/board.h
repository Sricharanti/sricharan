/*
 * board.h
 *
 * TI AM335x boards information header
 *
 * Copyright (C) 2011, Texas Instruments, Incorporated - http://www.ti.com/
 *
 * SPDX-License-Identifier:	GPL-2.0+
 */

#ifndef _BOARD_H_
#define _BOARD_H_

/*
 * TI AM335x parts define a system EEPROM that defines certain sub-fields.
 * We use these fields to in turn see what board we are on, and what
 * that might require us to set or not set.
 */
#define HDR_NO_OF_MAC_ADDR	3
#define HDR_ETH_ALEN		6
#define HDR_NAME_LEN		8

struct am335x_baseboard_id {
	unsigned int  magic;
	char name[HDR_NAME_LEN];
	char version[4];
	char serial[12];
	char config[32];
	char mac_addr[HDR_NO_OF_MAC_ADDR][HDR_ETH_ALEN];
};

static inline int board_is_bone(struct am335x_baseboard_id *header)
{
	return !strncmp(header->name, "A335BONE", HDR_NAME_LEN);
}

static inline int board_is_bone_lt(struct am335x_baseboard_id *header)
{
	return !strncmp(header->name, "A335BNLT", HDR_NAME_LEN);
}

static inline int board_is_evm_sk(struct am335x_baseboard_id *header)
{
	return !strncmp("A335X_SK", header->name, HDR_NAME_LEN);
}

static inline int board_is_idk(struct am335x_baseboard_id *header)
{
	return !strncmp(header->config, "SKU#02", 6);
}

static inline int board_is_gp_evm(struct am335x_baseboard_id *header)
{
	return !strncmp("A33515BB", header->name, HDR_NAME_LEN);
}

static inline int board_is_evm_15_or_later(struct am335x_baseboard_id *header)
{
	return (board_is_gp_evm(header) &&
		strncmp("1.5", header->version, 3) <= 0);
}

/*
 * The AM335x GP EVM, if daughter card(s) are connected, can have 8
 * different profiles.  These profiles determine what peripherals are
 * valid and need pinmux to be configured.
 */
#define PROFILE_NONE	0x0
#define PROFILE_0	(1 << 0)
#define PROFILE_1	(1 << 1)
#define PROFILE_2	(1 << 2)
#define PROFILE_3	(1 << 3)
#define PROFILE_4	(1 << 4)
#define PROFILE_5	(1 << 5)
#define PROFILE_6	(1 << 6)
#define PROFILE_7	(1 << 7)
#define PROFILE_MASK	0x7
#define PROFILE_ALL	0xFF

/* CPLD registers */
#define I2C_CPLD_ADDR	0x35
#define CFG_REG		0x10

static inline unsigned short detect_daughter_board_profile(void)
{
	unsigned short val;

	if (i2c_probe(I2C_CPLD_ADDR))
		return PROFILE_NONE;

	if (i2c_read(I2C_CPLD_ADDR, CFG_REG, 1, (unsigned char *)(&val), 2))
		return PROFILE_NONE;

	return (1 << (val & PROFILE_MASK));
}

/*
 * We have three pin mux functions that must exist.  We must be able to enable
 * uart0, for initial output and i2c0 to read the main EEPROM.  We then have a
 * main pinmux function that can be overridden to enable all other pinmux that
 * is required on the board.
 */
void enable_uart0_pin_mux(void);
void enable_uart1_pin_mux(void);
void enable_uart2_pin_mux(void);
void enable_uart3_pin_mux(void);
void enable_uart4_pin_mux(void);
void enable_uart5_pin_mux(void);
void enable_i2c0_pin_mux(void);
void enable_board_pin_mux(struct am335x_baseboard_id *header);
#endif
