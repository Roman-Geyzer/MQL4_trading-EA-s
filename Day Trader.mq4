//+------------------------------------------------------------------+
//|                                                   Day Trader.mq4 |
//|                                                     Roman Geyzer |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Roman Geyzer"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

// extrenal varibles: 

extern int MagicNumber = 123456;
//will be changed per currency pair

extern double RR_ratio = 2;


extern int FirstTradingHour = 2;
extern int LastTradingHour = 22;
int TradingMinutes = 00; // not in use
//Trades placed at te begining of the hour

// following is trading general configoration strategy


extern bool UseRR = false; 
// RR will overide SL and TP - only relevent for: range, double, trend, last candles SL
bool UseTP = true;// not in use
//TP can be false if usuing exit strategy

// following only chooses strategies to use

extern bool UseMA = false;
extern bool UsePatterns = false; 
extern bool UseHA = false; 
extern bool UseSR = false; 
extern bool UseBreakOut = false; 
extern bool UseRange = false; 
extern bool UseDouble = false; 
bool UseBB = false; // not in use




// following only relevent for strategies combination and confirmation - need to make sure that in use in all subfunctions in strategies functions
extern bool ConfirmWithMA = false;
extern bool ConfirmWithHA = false;
extern bool ConfirmWithPattern = false;
extern bool ConfirmWithFIB = false;
extern bool ConfirmWithRSI = false;
extern bool ConfirmWithBB = false;
bool ConfirmWithMACD = false; // not in use
//cinfirm with BB - dont buy low and sell high

// following only relevent for managing trades using strategy
extern bool UseMAExit = false;
extern bool UseSRExit = false;
extern bool UseBreakOutExit = false;
extern bool UseHAExit = false;
extern bool UseBBExit = false;
extern bool UsePatternsExit = false;
extern bool UseDoubleExit = false;
//extern bool UseRangExit = false; no need - SR covers
bool UseMACDExit = false;//not in use
bool UseCloseSLExit = false;//not in use
// Engulfing and doji+ another candle


/* ******************* decided to keep out for the meantime - MACD strategy
extern double MACDFastEMA=12;
extern double MACDSlowEMA=26;
extern double MACDSMA=9;
extern double MACDLimit=9;
*/


#include <Open Orders include.mqh>
#include <Manage Open Trades include.mqh>
#include <HA include.mqh>
#include <MA include.mqh>
#include <Range include.mqh>
#include <Double include.mqh>
#include <BB include.mqh>
#include <RSI include.mqh>
#include <FIB include.mqh>
#include <Pattern include.mqh>
//#include <Close SL include.mqh>

int OnInit() {  return(INIT_SUCCEEDED);}

void OnDeinit(const int reason) {  }

//+------------------------------------------------------------------+
//| Start of General functions:                               |
//+------------------------------------------------------------------+

double CalculateLotSize(double SL) //Calculate the size of the position size 
{         
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE); //We get the value of a tick
   if (Symbol() == "XAUUSD")  nTickValue=nTickValue*100;
//   Print( "nTickValue is " ,  nTickValue) ;
   double LotSize=(AccountBalance()*MaxRiskPerTrade/100)/(SL*nTickValue);   //We apply the formula to calculate the position size and assign the value to the variable
//   Print( "LotSize is " , LotSize) ;
   return LotSize/10;
}

double CalculatePipSize() //Calculate the size of the position size 
{         
   return (Point*10);
}

void OnTick()
{
//    Comment (" hour  is : "  , TimeHour (TimeCurrent ()));
    if (IsNewCandle() && TimeHour (TimeCurrent())>= FirstTradingHour && TimeHour (TimeCurrent ())<=LastTradingHour )
    {
        if (OpenOrdersThisPair (Symbol()) ==0)
        {       
              if (check_is_buy ()) PlaceBuyOrder();
              else if (check_is_sell() ) PlaceSellOrder();
        }
       // else check_open_trade ()
     }
    if (OpenOrdersThisPair (Symbol()) ==1 && TimeMinute (TimeCurrent () - OrderOpenTime())> Period() ) manage_open_trade();
    if (OpenOrdersThisPair (Symbol()) ==1) manage_SL();
}


