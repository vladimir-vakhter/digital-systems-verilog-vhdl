/*
 * uart baud rate: 9600
 * VGA display resolution: 640*480pixels.
 * ker 'r' - runs/restarts the game
 * key 'w' - decrease the y-position of the platform 1 on the VGA display on 16 pixels
 * key 's' - increase the y-position of the platform 1 on the VGA display on 16 pixels
 * key 'i' - decrease the y-position of the platform 2 on the VGA display on 16 pixels
 * key 'k' - increase the y-position of the platform 2 on the VGA display on 16 pixels
 */

#include <stdio.h>
#include "platform.h"
#include "xparameters.h"
#include "xiomodule.h"
#include "xil_printf.h"

//#define DEBUG

const u8  BORDER_WIDTH		= 10;
const u8  Y_UP_BORDER 		= 19;
const u16 Y_DOWN_BORDER		= 460;
const u8  PLATFORM_HEIGHT 	= 48;
const u8  START_GAME 		= 1;
const u8  STOP_GAME 		= 0;

int main()
{
    init_platform();

	//initialize iomodules in the system
	XIOModule gpo;
//  XIOModule gpi;

	XIOModule_Initialize(&gpo, XPAR_IOMODULE_0_DEVICE_ID);
    XIOModule_Start(&gpo);

//	XIOModule_Initialize(&gpi, XPAR_IOMODULE_0_DEVICE_ID);
//  XIOModule_Start(&gpi);

    //the min and max y-position of the platform in pixels
    u16 min_y_pos = Y_UP_BORDER + BORDER_WIDTH;
    u16 max_y_pos = Y_DOWN_BORDER - BORDER_WIDTH - PLATFORM_HEIGHT;

	//current date
	u8	day		= 4;
	u8	month	= 12;
	u16 year	= 2019;

	//showing the date and the name of the developer
	xil_printf("Current date: %d/%d/%d, Developer: Vladimir Vakhter\n\r", month, day, year);

	//keyboard key
	u8 kb_key_code = 0;

	//channels of the GPI/GPO (1, 2, 3 or 4) to operate on
	const u8 y_pos_1_ch = 1; 	// GPO: the y-position of the paddle 1
	const u8 y_pos_2_ch = 2; 	// GPO: the y-position of the paddle 2
	const u8 ctrl_ch  	= 3;	// GPO: control (0 - stop a game, 1 - start a game)

	//control computation
	u8 ctrl = STOP_GAME;
	XIOModule_DiscreteWrite(&gpo, ctrl_ch, ctrl);

	//the default y-positions of the paddles
	u32 y_pos_cur_1 = 216;
	u32 y_pos_cur_2 = 216;

	//send the current y-positions of the paddles to the hardware module
	XIOModule_DiscreteWrite(&gpo, y_pos_1_ch, y_pos_cur_1);
	XIOModule_DiscreteWrite(&gpo, y_pos_2_ch, y_pos_cur_2);

    while(1) {
    	//update the y-position of a paddle
    	kb_key_code = inbyte();	// it is blocking - waits for the receiver to become non-empty before it reads from the receive register

    	switch (kb_key_code) {
    		//r
    		case 114:
				{
					if (ctrl == START_GAME) {
						ctrl = STOP_GAME;
					} else {
						ctrl = START_GAME;
					}
					XIOModule_DiscreteWrite(&gpo, ctrl_ch, ctrl);
				}
				break;
    		//w
    		case 119:
				{
					if (y_pos_cur_1 > min_y_pos) {
						y_pos_cur_1 -= 16;
					}
				}
				break;
			//s
    		case 115:
				{
					if (y_pos_cur_1 < max_y_pos) {
						y_pos_cur_1 += 16;
					}
				}
				break;
			//i
			case 105:
				{
					if (y_pos_cur_2 > min_y_pos) {
						y_pos_cur_2 -= 16;
					}
				}
				break;
			//k
			case 107:
				{
					if (y_pos_cur_2 < max_y_pos) {
						y_pos_cur_2 += 16;
					}
				}
				break;
    		default:
				break;
		}
    	//send the current y-positions of the paddles to the hardware module
    	XIOModule_DiscreteWrite(&gpo, y_pos_1_ch, y_pos_cur_1);
    	XIOModule_DiscreteWrite(&gpo, y_pos_2_ch, y_pos_cur_2);
    	//show the current y-position of the paddles on the PuTTY terminal
    	xil_printf("y_player_1 = %d, y_player_2 = %d\n\r", y_pos_cur_1, y_pos_cur_2);
    }

    cleanup_platform();
    return 0;
}
