/*
 * Company: WPI, ECE
 * Engineer: Vladimir Vakhter
 * Create Date: 11/10/2019
 * Description: this hardware module combines:
 * *    a 64-bit unsigned divider: input - a 64-bit dividend, a 64-bit divider in hex format,
 *      output - a 64-bit quotient, a 64-bit reminder in hex format.
 * *    a 128-bit multiplier: inputs - 2 128-bit numbers in hex format.
 * The input numbers are entered via the PuTTY terminal. The outputs are displayed on the PuTTY terminal.
 */

#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xiomodule.h"
#include "xil_printf.h"

//#define DEBUG

typedef struct
{
	u8	day;
	u8	month;
	u16 year;
} date;

//64-bit number
typedef struct
{
	u32 num_0;	//low 32 bits
	u32 num_1;  //high 32 bits
} num64_t;

//read 64-bit input number
num64_t read_input_64()
{
	num64_t in = {0, 0};			//input number
	u8 rx_buf[16] = {0};			//receive buffer

    //read input chars
    for (u8 i = 0; i < 16; ++i) {
    	//read a byte from terminal
    	rx_buf[i] = inbyte();
    	//check that the input is valid (0-9, a-f)
    	switch (rx_buf[i]) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6':	case '7': case '8':	case '9':
				xil_printf("%c", rx_buf[i]);
				rx_buf[i] = rx_buf[i] - 48;		//convert from the ASCII-code to a number
				break;
			case 'a': case 'b': case 'c':
			case 'd': case 'e':	case 'f':
				xil_printf("%c", rx_buf[i]);
				rx_buf[i] = rx_buf[i] - 87;		//convert from the ASCII-code to a number
				break;
			default:
				//forbidden symbol
				--i;
				break;
		}

    	if (((i + 1) % 8) == 0) {
			if ((i + 1) == 16) {
				xil_printf("\r\n");
			} else {
				xil_printf("_");
			}
		}
    }

    for (int j = 7; j > -1; --j) {
    	in.num_1 |= (rx_buf[j] << (28 - 4 * j));
	}

    for (int j = 15; j > 7; --j) {
    	in.num_0 |= (rx_buf[j] << (28 - 4 * (j - 8)));
	}

	return in;
}

//128-bit number
typedef struct
{
	u32 num_0;	//low 32 bits
	u32 num_1;  //
	u32 num_2;  //
	u32 num_3;  //high 32 bits
} num128_t;

//read 128-bit input number
num128_t read_input_128()
{
	num128_t in = {0, 0, 0, 0};		//input number
	u8 rx_buf[32] = {0};			//receive buffer

    //read input chars
    for (u8 i = 0; i < 32; ++i) {
    	//read a byte from terminal
    	rx_buf[i] = inbyte();
    	//check that the input is valid (0-9, a-f)
    	switch (rx_buf[i]) {
			case '0': case '1': case '2': case '3': case '4':
			case '5': case '6':	case '7': case '8':	case '9':
				xil_printf("%c", rx_buf[i]);
				rx_buf[i] = rx_buf[i] - 48;		//convert from the ASCII-code to a number
				break;
			case 'a': case 'b': case 'c':
			case 'd': case 'e':	case 'f':
				xil_printf("%c", rx_buf[i]);
				rx_buf[i] = rx_buf[i] - 87;		//convert from the ASCII-code to a number
				break;
			default:
				//forbidden symbol
				--i;
				break;
		}

    	if (((i + 1) % 8) == 0) {
			if ((i + 1) == 32) {
				xil_printf("\r\n");
			} else {
				xil_printf("_");
			}
		}
    }

    for (int j = 7; j > -1; --j) {
    	in.num_3 |= (rx_buf[j] << (28 - 4 * j));
	}

    for (int j = 15; j > 7; --j) {
    	in.num_2 |= (rx_buf[j] << (28 - 4 * (j - 8)));
	}

    for (int j = 23; j > 15; --j) {
    	in.num_1 |= (rx_buf[j] << (28 - 4 * (j - 16)));
	}

    for (int j = 31; j > 23; --j) {
    	in.num_0 |= (rx_buf[j] << (28 - 4 * (j - 24)));
	}

	return in;
}

int main()
{
    init_platform();

	//initialize input and output modules in the system
	XIOModule gpo;
    XIOModule gpi;

	XIOModule_Initialize(&gpo, XPAR_IOMODULE_0_DEVICE_ID);
    XIOModule_Start(&gpo);

	XIOModule_Initialize(&gpi, XPAR_IOMODULE_0_DEVICE_ID);
    XIOModule_Start(&gpi);

	//channels of the GPI/GPO (1, 2, 3 or 4) to operate on
    const u8 out_loc_ch		= 1;	// GPI: a location for a 32-bit chunk of the 64-bit output values
    const u8 out_value_ch	= 2;	// GPI: the 32-bit chunk output value
	const u8 state_ch		= 3;	// GPI: a state

	const u8 in_index_ch	= 1; 	// GPO: the index location for a 32-bit chunk of the 128-bit input value
	const u8 in_value_ch	= 2; 	// GPO: the 32-bit chunk input value
	const u8 ctrl_ch		= 3; 	// GPO: control computation: 0 - start/reset, 1 - stop
	const u8 enable_ch		= 4;	// GPO: 0 - enable multiplier, 1 - enable divider

	//locations of the 32-bit chunks of the input numbers
	const u32 LOC_1 = 1;
	const u32 LOC_2 = 2;
	const u32 LOC_3 = 3;
	const u32 LOC_4 = 4;
	const u32 LOC_5 = 5;
	const u32 LOC_6 = 6;
	const u32 LOC_7 = 7;

	//select hardware: 0 - multiplier, 1 - divider
	u32 select = 0x0;

	//the final state
    const u32 FINAL = 4;

    //showing the current date and the name of the developer
	date today = {5, 11, 1992};
	xil_printf("\r\n\nCurrent date: %d/%d/%d, Developer: Vladimir Vakhter\r\n\n", today.month, today.day, today.year);

	//showing the directions
	xil_printf("Would you like to multiply(m) or divide(d)? ");

	u8 rx_buf[1];			//receive buffer
	do {
		rx_buf[0] = inbyte();
		if (rx_buf[0] == 'd') break;
	} while (rx_buf[0] != 'm');
	xil_printf("%c\r\n\n", rx_buf[0]);

	//multiplier
	if (rx_buf[0] == 'm') {
		//activate the hardware multiplier
		XIOModule_DiscreteWrite(&gpo, enable_ch, select);

		//locations of the 32-bit chunks of the input numbers
		const u32 LOC_8 = 8;
		const u32 LOC_9 = 9;
		const u32 LOC_10 = 10;
		const u32 LOC_11 = 11;
		const u32 LOC_12 = 12;
		const u32 LOC_13 = 13;
		const u32 LOC_14 = 14;
		const u32 LOC_15 = 15;

	    xil_printf("This is a 128-bit multiplier.\r\n");
		xil_printf("Input: two 128-bit hexadecimal numbers.\r\n");
		xil_printf("Output: a 256-bit hexadecimal number.\r\n");
		xil_printf("Follow the directions below to start.\r\n\n");
		xil_printf("Enter 2 hexadecimal numbers starting from the most significant digit.\r\n\n");

		//input number 1
		xil_printf("Input1: ");
		num128_t in1 = read_input_128();

		//input number 2
		xil_printf("Input2: ");
		num128_t in2 = read_input_128();

		//result (256-bit number)
		struct {
			num128_t low;
			num128_t high;
		} result;

		//write the input values to hardware multiplier
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_1);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in1.num_0);

		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_2);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in1.num_1);

		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_3);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in1.num_2);

		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_4);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in1.num_3);

		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_5);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in2.num_0);

		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_6);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in2.num_1);

		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_7);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in2.num_2);

		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_8);
		XIOModule_DiscreteWrite(&gpo, in_value_ch, in2.num_3);

		//start computation
		u32 ctrl = 0x1;
		XIOModule_DiscreteWrite(&gpo, ctrl_ch, ctrl);

		//monitor the current state of the hardware multiplier
		u32 state = XIOModule_DiscreteRead(&gpi, state_ch);
		while (state != FINAL) {
			state = XIOModule_DiscreteRead(&gpi, state_ch);
		}

		//read out the result from the hardware module
		u32 out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		while (out_loc != LOC_1) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.low.num_0 = XIOModule_DiscreteRead(&gpi, out_value_ch);
		//send delivery confirmation
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_9);

		while (out_loc != LOC_2) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.low.num_1 = XIOModule_DiscreteRead(&gpi, out_value_ch);
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_10);

		while (out_loc != LOC_3) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.low.num_2 = XIOModule_DiscreteRead(&gpi, out_value_ch);
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_11);

		while (out_loc != LOC_4) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.low.num_3 = XIOModule_DiscreteRead(&gpi, out_value_ch);
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_12);

		while (out_loc != LOC_5) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.high.num_0 = XIOModule_DiscreteRead(&gpi, out_value_ch);
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_13);

		while (out_loc != LOC_6) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.high.num_1 = XIOModule_DiscreteRead(&gpi, out_value_ch);
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_14);

		while (out_loc != LOC_7) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.high.num_2 = XIOModule_DiscreteRead(&gpi, out_value_ch);
		XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_15);

		while (out_loc != LOC_8) {
			out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
		}
		result.high.num_3 = XIOModule_DiscreteRead(&gpi, out_value_ch);

		//display the result
		xil_printf("Result: %08x_%08x_%08x_%08x_%08x_%08x_%08x_%08x\r\n",
					result.high.num_3, result.high.num_2, result.high.num_1, result.high.num_0,
					result.low.num_3, result.low.num_2, result.low.num_1, result.low.num_0);
	//divider
	} else {
		//activate the hardware divider
		select = 0x1;
		XIOModule_DiscreteWrite(&gpo, enable_ch, select);

		//showing the directions on how to use the multiplier
	    xil_printf("This is a 64-bit divider.\r\n");
	    xil_printf("Input: dividend, divider - two 64-bit hexadecimal numbers.\r\n");
	    xil_printf("Output: a 64-bit hexadecimal number.\r\n");
	    xil_printf("Follow the directions below to start.\r\n\n");

	    xil_printf("Enter 2 hexadecimal numbers starting from the most significant digit.\r\n\n");

	    //input number 1
	    xil_printf("Dividend: ");
	    num64_t dividend = read_input_64();

		//input number 2
		xil_printf("Divider:  ");
		num64_t divider = read_input_64();

		if ((divider.num_1 == 0) && (divider.num_0 == 0)) {
			xil_printf("Division by zero! Please, reset.");
		} else {
			//write dividend/divider to hardware module
			XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_1);
			XIOModule_DiscreteWrite(&gpo, in_value_ch, dividend.num_0);

			XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_2);
			XIOModule_DiscreteWrite(&gpo, in_value_ch, dividend.num_1);

			XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_3);
			XIOModule_DiscreteWrite(&gpo, in_value_ch, divider.num_0);

			XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_4);
			XIOModule_DiscreteWrite(&gpo, in_value_ch, divider.num_1);

			//result (64-bit number)
			num64_t quotient;
			num64_t reminder;

			//start computation
			u32 ctrl = 0x1;
			XIOModule_DiscreteWrite(&gpo, ctrl_ch, ctrl);

			//wait until the divider goes to its final state
			u32 state = XIOModule_DiscreteRead(&gpi, state_ch);
			while (state != FINAL) {
				state = XIOModule_DiscreteRead(&gpi, state_ch);
			}

			//read out the result from the hardware module
			u32 out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
			while (out_loc != LOC_1) {
				out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
			}
			quotient.num_0 = XIOModule_DiscreteRead(&gpi, out_value_ch);
			//send delivery confirmation
			XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_5);

			while (out_loc != LOC_2) {
				out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
			}
			quotient.num_1 = XIOModule_DiscreteRead(&gpi, out_value_ch);
			XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_6);

			while (out_loc != LOC_3) {
				out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
			}
			reminder.num_0 = XIOModule_DiscreteRead(&gpi, out_value_ch);
			XIOModule_DiscreteWrite(&gpo, in_index_ch, LOC_7);

			while (out_loc != LOC_4) {
				out_loc = XIOModule_DiscreteRead(&gpi, out_loc_ch);
			}
			reminder.num_1 = XIOModule_DiscreteRead(&gpi, out_value_ch);

			//display the result
			xil_printf("Quotient: %08x_%08x\r\n", quotient.num_1, quotient.num_0);
			xil_printf("Reminder: %08x_%08x\r\n", reminder.num_1, reminder.num_0);
		}
	}

    cleanup_platform();
    return 0;
}
