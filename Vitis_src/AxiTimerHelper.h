/*
 * AxiTimerHelper.h
 *
 *  Created on: 06/07/2015
 *      Author: laraujo
 */

#ifndef AXITIMERHELPER_H_
#define AXITIMERHELPER_H_

#include "xil_types.h"
#include "xtmrctr.h"
#include "xparameters.h"

	void AxiTimerHelper();
	unsigned int getElapsedTicks();
	double getElapsedTimerInSeconds();
	unsigned int startTimer();
	unsigned int stopTimer();
	double getClockPeriod();
	double getTimerClockFreq();




#endif /* AXITIMERHELPER_H_ */
