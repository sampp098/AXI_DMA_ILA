#include "AxiTimerHelper.h"

XTmrCtr m_AxiTimer;
unsigned int m_tickCounter1;
unsigned int m_tickCounter2;
double m_clockPeriodSeconds;
double m_timerClockFreq;

void AxiTimerHelper() {
	// Initialize the timer hardware...
	 XTmrCtr_Initialize(&m_AxiTimer, XPAR_TMRCTR_0_BASEADDR);

	 //XTmrCtr_SetOptions(&m_AxiTimer, 0, XTC_AUTO_RELOAD_OPTION);

	 // Get the clock period in seconds
	 m_timerClockFreq = (double) XPAR_AXI_TIMER_0_CLOCK_FREQ_HZ;
	 m_clockPeriodSeconds = (double)1/m_timerClockFreq;

}


unsigned int getElapsedTicks() {
	return m_tickCounter2 - m_tickCounter1;
}

unsigned int startTimer() {
	// Start timer 0 (There are two, but depends how you configured in vivado)
	XTmrCtr_Reset(&m_AxiTimer,0);
	m_tickCounter1 =  XTmrCtr_GetValue(&m_AxiTimer, 0);
	XTmrCtr_Start(&m_AxiTimer, 0);
	return m_tickCounter1;
}

unsigned int stopTimer() {
	XTmrCtr_Stop(&m_AxiTimer, 0);
	m_tickCounter2 =  XTmrCtr_GetValue(&m_AxiTimer, 0);
	return m_tickCounter2 - m_tickCounter1;
}

double getElapsedTimerInSeconds() {
	double elapsedTimeInSeconds = (double)(m_tickCounter2 - m_tickCounter1) * m_clockPeriodSeconds;
	return elapsedTimeInSeconds;
}

double getClockPeriod() {
	return m_clockPeriodSeconds;
}

double getTimerClockFreq() {
	return m_timerClockFreq;
}
