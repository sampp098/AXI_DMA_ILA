/*
 * Empty C++ Application
 */

/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include "platform.h"
#include "xil_printf.h"

#include "xil_io.h"
#include "xscugic.h"
#include "AxiTimerHelper.h"
//#include "data_10k.h"
#include "xparameters.h"
#include <math.h>

//u32 SG_BRAM_ADDR = XPAR_AXI_BRAM_CTRL_0_S_AXI_BASEADDR;
//#define SG_BRAM_ADDR 0xa0000000


//----------------------------------------------------
// Interrupt controller
XScuGic InterruptController;
static XScuGic_Config *GicConfig;

void setCacheWriteDirection(u32 value){
	Xil_Out32(XPAR_AXIS_CACHE_HDL_V1_0_0_BASEADDR+0X00, value);
}

void setWriteStreamPuls(){
	Xil_Out32(XPAR_AXIS_CACHE_HDL_V1_0_0_BASEADDR+0X04, 0X1);
}
void resetWriteStreamPuls(){
	Xil_Out32(XPAR_AXIS_CACHE_HDL_V1_0_0_BASEADDR+0X04, 0X0);
}
void setReadStreamPuls(){
	Xil_Out32(XPAR_AXIS_CACHE_HDL_V1_0_0_BASEADDR+0X08, 0X1);
}
void resetReadStreamPuls(){
	Xil_Out32(XPAR_AXIS_CACHE_HDL_V1_0_0_BASEADDR+0X08, 0X0);
}

u32 readStatus(){
	return Xil_In32(XPAR_AXIS_CACHE_HDL_V1_0_0_BASEADDR+0X0C);
}
u32 writeStatus(){
	return Xil_In32(XPAR_AXIS_CACHE_HDL_V1_0_0_BASEADDR+0X10);
}

void InterruptHandler ( void ) {
	// if you have a device, which may produce several interrupts one after another, the first thing you should do is to disable interrupts. but axi dma is not this case.
	u32 tmpValue;

	print ("Interrupt acknowledged.\n\r");

	// clear interrupt.
	tmpValue = Xil_In32 ( XPAR_AXI_DMA_0_BASEADDR + 0x34 );
	tmpValue = tmpValue | 0x1000;
	Xil_Out32 ( XPAR_AXI_DMA_0_BASEADDR + 0x34 , tmpValue );

	//////////////////////////////////////////////////////////////////
	//
	// Data is in the DRAM ! do your processing here !
	//
	//////////////////////////////////////////////////////////////////

	print ("interrupt---------------.\n\r");
}

int SetUpInterruptSystem(XScuGic *XScuGicInstancePtr)
{
	xil_printf("SetUpInterruptSystem...\n\r");
	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT, (Xil_ExceptionHandler) XScuGic_InterruptHandler, XScuGicInstancePtr);
	Xil_ExceptionEnable();		// enable interrupts in ARM.
	return XST_SUCCESS;
}

int InitializeInterruptSystem  ( u16 deviceID ) {
	xil_printf("InitializeInterruptSystem...\n\r");
	int Status;

	GicConfig = XScuGic_LookupConfig ( deviceID );
	if ( NULL == GicConfig ) {
		return XST_FAILURE;
	}

	Status = XScuGic_CfgInitialize ( &InterruptController, GicConfig, GicConfig->CpuBaseAddress);
	if ( Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = SetUpInterruptSystem ( &InterruptController);
	if ( Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	Status = XScuGic_Connect ( &InterruptController,
			XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR,
			(Xil_ExceptionHandler)InterruptHandler,
			NULL);
	if ( Status != XST_SUCCESS) {
		return XST_FAILURE;
	}

	XScuGic_Enable (&InterruptController, XPAR_FABRIC_AXI_DMA_0_S2MM_INTROUT_INTR);

	return XST_SUCCESS;
}

//----------------------------------------------------
/*
####################################
#
# Reset DMA and Init
#
####################################
# configure MM2S
# no cyclic bd for now
# reset MM2S
mwr XPAR_AXI_DMA_0_BASEADDR+0x00 0x0101dfe6
mwr XPAR_AXI_DMA_0_BASEADDR+0x00 0x0101dfe2

# configure S2MM
# Reset S2MM
mwr XPAR_AXI_DMA_0_BASEADDR+0x30 0x0101dfe6
mwr XPAR_AXI_DMA_0_BASEADDR+0x30 0x0101dfe2
*/
void initDMA(){
	print("initDMA\n\r");

	// reset MM2S
	Xil_Out32((volatile u32 *) XPAR_AXI_DMA_0_BASEADDR+0x00, (u32) 0x0101dfe6);
	Xil_Out32((volatile u32 *) XPAR_AXI_DMA_0_BASEADDR+0x00, (u32) 0x0101dfe2);

	//# configure S2MM
	Xil_Out32((volatile u32 *) XPAR_AXI_DMA_0_BASEADDR+0x30, (u32) 0x0101dfe6);
	Xil_Out32((volatile u32 *) XPAR_AXI_DMA_0_BASEADDR+0x30, (u32) 0x0101dfe2);

}

/*
####################################
#
# Write Descriptors
#
####################################
# write descriptors to bram
# this we use as the mm2s descriptor. one descriptor transfers one complete packet. (both of sof and eof are set)
mwr SG_BRAM_ADDR + 0x0000 SG_BRAM_ADDR + 0x0000
mwr SG_BRAM_ADDR + 0x0004 0x00000000
mwr SG_BRAM_ADDR + 0x0008 0x00a00000 //start file lsb
mwr SG_BRAM_ADDR + 0x000c 0x00000000 //start file msb
mwr SG_BRAM_ADDR + 0x0010 0x00000000
mwr SG_BRAM_ADDR + 0x0014 0x00000000
mwr SG_BRAM_ADDR + 0x0018 [expr 0x0c000000+$transferSize] //num of bytes
mwr SG_BRAM_ADDR + 0x001c 0x00000000
mwr SG_BRAM_ADDR + 0x0020 0x00000000
mwr SG_BRAM_ADDR + 0x0024 0x00000000
mwr SG_BRAM_ADDR + 0x0028 0x00000000
mwr SG_BRAM_ADDR + 0x002c 0x00000000
mwr SG_BRAM_ADDR + 0x0030 0x00000000

# descriptor for s2mm , these descriptors begin from 0x1000 offset in the block memory.
mwr SG_BRAM_ADDR + 0x1000 SG_BRAM_ADDR + 0x1000
mwr SG_BRAM_ADDR + 0x1004 0x00000000
mwr SG_BRAM_ADDR + 0x1008 0x00b00000 //start file lsb
mwr SG_BRAM_ADDR + 0x100c 0x00000000 //start file msb
mwr SG_BRAM_ADDR + 0x1010 0x00000000
mwr SG_BRAM_ADDR + 0x1014 0x00000000
mwr SG_BRAM_ADDR + 0x1018 [expr 0x0c000000+$transferSize] //num of bytes
mwr SG_BRAM_ADDR + 0x101c 0x00000000
mwr SG_BRAM_ADDR + 0x1020 0x00000000
mwr SG_BRAM_ADDR + 0x1024 0x00000000
mwr SG_BRAM_ADDR + 0x1028 0x00000000
mwr SG_BRAM_ADDR + 0x102c 0x00000000
mwr SG_BRAM_ADDR + 0x1030 0x00000000
*/

u32 sendDescriptors(u32 SG_BRAM_ADDR,u32 byteSize, u32 data_addr){

	print("write Descriptors\n\r");

	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0000), (u32) SG_BRAM_ADDR);//next Descriptor (LSB)
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0004), (u32) 0x00000000);// MSB
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0008), (u32) data_addr);//Buffer Address (LSB)
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x000c), (u32) 0x00000000);//Buffer Address (MSB
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0010), (u32) 0x00000000);//Reserved
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0014), (u32) 0x00000000);//Reserved

	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0018), (u32) 0x0c000000+byteSize); //[expr 0x0c000000+$transferSize]

	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x001c), (u32) 0x00000000);//DMA Status, for check after transfer
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0020), (u32) 0x00000000);//User App Fields
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0024), (u32) 0x00000000);//User App Fields
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0028), (u32) 0x00000000);//User App Fields
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x002c), (u32) 0x00000000);//User App Fields
	Xil_Out32((volatile u32 *) (SG_BRAM_ADDR + 0x0030), (u32) 0x00000000);//User App Fields

	return SG_BRAM_ADDR + 0x0100;
}

/*
 ####################################
#
# Initialize DRAM
#
####################################
# initialize memory which is read by mm2s
# WARNING ! If the transferSize is a big number, this code takes a long while to be executed in XMD.

for {set i 0} {$i < $transferWords} {incr i 1} {
	mwr [expr 0x00a00000+$i*4] [expr 0xa0000000+$i]
}

# initializing memory which is being written to by s2mm
for {set i 0} {$i < $transferWords} {incr i 1} {
	mwr [expr 0x00b00000+$i*4] 0xbbbbbbbb
}
 */

/*
 ####################################
#
# start S2MM
#
####################################
# for s2mm write the current descriptor pointer
mwr XPAR_AXI_DMA_0_BASEADDR+0x3c 0x00000000
mwr XPAR_AXI_DMA_0_BASEADDR+0x38 SG_BRAM_ADDR + 0x1000

# start s2mm engine
mwr XPAR_AXI_DMA_0_BASEADDR+0x30 0x0101dfe3// for cyclic 0X0101dff3

# for s2mm write tail descriptor pointer
mwr XPAR_AXI_DMA_0_BASEADDR+0x44 0x00000000
mwr XPAR_AXI_DMA_0_BASEADDR+0x40 SG_BRAM_ADDR + 0x1000
*/
void startS2MM(u32 descAddr){
	print("startS2MM\n\r");
	Xil_Out32((volatile u32 *) (descAddr+0x1c), (u32) 0x00000000); //reset transfered value from Desc
	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x3c), (u32) 0x00000000);
	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x38), (u32) descAddr);//Descriptor address

	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x30), (u32) 0x0101dfe3);

	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x44), (u32) 0x00000000);
	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x40), (u32) descAddr);
}

/*
 ####################################
#
# Start MM2S
#
####################################
# for mm2s write the value of current descriptor and tail descriptor
mwr XPAR_AXI_DMA_0_BASEADDR+0x0c 0x00000000
mwr XPAR_AXI_DMA_0_BASEADDR+0x08 SG_BRAM_ADDR + 0x0000

# enable mm2s
mwr XPAR_AXI_DMA_0_BASEADDR+0x00 0x0101dfe3

# # mm2s tail desc pointer. write msb first.
mwr XPAR_AXI_DMA_0_BASEADDR+0x14 0x00000000
mwr XPAR_AXI_DMA_0_BASEADDR+0x10 SG_BRAM_ADDR + 0x0000
 */
void startMM2S(u32 descAddr){
	print("startMM2S\n\r");
	Xil_Out32((volatile u32 *) (descAddr+0x1c), (u32) 0x00000000); //reset transfered value from Desc
	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x0c), (u32) 0x00000000);
	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x08), (u32) descAddr);//Descriptor address

	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x00), (u32) 0x0101dfe3);

	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x14), (u32) 0x00000000);
	Xil_Out32((volatile u32 *) (XPAR_AXI_DMA_0_BASEADDR+0x10), (u32) descAddr);
}

/*
 ####################################
#
# Start Packet Generator
#
####################################
# now start the sample generator
mwr 0x43c00004 $transferSize
mwr 0x43c00000 0x01
 */


int main()
{
    init_platform();
    Xil_DCacheDisable();
    printf("Start the app ... \n\r");
    //InitializeInterruptSystem ( XPAR_SCUGIC_0_DEVICE_ID );
    int byteSize = 32*4;
    u8 data_toMM[32][4];
    u8 data_fromSlave[32][4];
    //initial data
    int count = 0;
    u32 row = 0;
    u32 col =0;

    u32 data_toMM_addr =  (u32)&data_toMM[0];
    u32 data_fromSlave_addr  =  (u32)&data_fromSlave [0];


    for(row =0; row <32; row++){
    	for(col=0; col<4; col++){
    		data_toMM[row][col] = count++;
    		data_fromSlave [row][col] = 0;
    	}
    }

    //Xil_DCacheFlush();

    int i=0;
    resetWriteStreamPuls();
    resetReadStreamPuls();

    initDMA();
    //Xil_DCacheFlush();
    u32 MM2S_base_addr =  XPAR_AXI_BRAM_CTRL_1_S_AXI_BASEADDR;
    u32 S2MM_base_addr;
    S2MM_base_addr = sendDescriptors( MM2S_base_addr,128, data_toMM_addr );
    sendDescriptors( S2MM_base_addr,128, data_fromSlave_addr);


    AxiTimerHelper();
    startTimer();
    //Xil_DCacheFlush();

    setCacheWriteDirection(0);
    int diff =0;
    for(i=0;i<15;i++){
    	printf("start new transaction \n\r");
		setWriteStreamPuls();
		resetWriteStreamPuls();

		startMM2S(MM2S_base_addr);


		startS2MM(S2MM_base_addr);
		setReadStreamPuls();
		resetReadStreamPuls();
		for(row =0; row <32; row++){
			for(col=0; col<4; col++){
				//data_out[row][col] = data_in[row][col];
				diff += (int)fabs( (double)(data_fromSlave[row][col] - data_toMM[row][col]));
				printf("data[%d][%d]= %d\n\r",row,col,data_fromSlave[row][col]);
			}
		}
    }

    print("End\n\r");
    printf("Diff = %d\n\r",diff);
    cleanup_platform();


    return 0;
}


