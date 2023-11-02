//+---------------------------------------------------------------------------------------------+
//|                                                                       Master Trader V43.mq4 |
//|2.0 Added filters, updated comments and system printouts                                     |
//|2.++Added exits based on short term moves (candles or pips)                                  |
//|3.0 added advance trail (start for trail based on time and profit,                           |
//|3.1 Added risk multiplier after loss, improved compatibility with all time frames            |
//|4.0 All entery must have pattern, pattern updated to include doji                            |
//|4++ SR updated to find the best SR level in last candles and bounce from it (or breakout)    |
//|4++ Range updated to reflectjust the extremes (no count of touches)                          |
//|4++ trail increments updated to 5 pips instead of 1                                          |
//|4++ updated comments and system printouts   (fixed misscomunication with iPhone              |
//|4.1 updated double logic - added pattern check to logic for both candles (enter and exit)    |
//|4.2 added close all position on total profit as precentage of accout or multiplier of RR     |
//|4.2 Added option to more then 1 trade per currency                                           |
//|4.2 Added option to close all positions at given time                                        |
//|4.3 Added SR exit                                                                            |
//|4.3 update use trailing exit - doesnt depent on trail start                                  |
//|                                                   Copyright 2020, MetaQuotes Software Corp. |
//|                                                                        https://www.mql5.com |
//+---------------------------------------------------------------------------------------------+

#property copyright "Roman Geyzer"
#property link      "https://www.mql5.com"
#property version   "4.30"
#property strict
#property show_inputs
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

// extrenal varibles: 

extern int MagicNumber = 123456;
//will be changed per currency pair
string rev ;


extern string MainS; // ***** main strategy *****     

extern bool UseSR = true; 
extern bool UseBreakOut = false; 
extern bool UseMA = false;
extern bool UseRange = false; 
extern bool UseDouble = false; 
extern bool UseBB = false;
extern bool UseHA = false; 


extern string TradeP; // ***** Trding parameters ***** 

extern double ExitOnPrecentProfit = 10;

extern int MaxOpenTrades = 10;

extern double UserRiskPerTrade=1;
extern double Martingale = 1;
double CurrentRiskPerTrade ;

extern bool UseTrailingSL = false;
extern double UserStopLoss=100;

extern bool UseTP = true;
extern bool UseRR = true; 
extern double RR_ratio = 2;
extern double UserTakeProfit=200; 
// RR will overide  all TP - only relevent for: SR, double, breakout

extern bool UseTrailingExit = false;
extern int CandlesForTrailing=200;
extern int PipsBufferForTrailing=10;
extern double Trail=300; 
extern double TrailStartPips=200;
extern int TrailStartCandles=200;


datetime Position_Open_time ;
bool Trail_Started = false;


double HighestTrail;
double LowestTrail; 


extern string EnterExitParemetes; // ***** Enter/Exit Paremetes *****

extern double Marubozu_Ratio = 2;
extern double Doji_Ratio = 0.2;

extern int ExitTradeOnXPipsMove = 100;
extern int CandlesCountForPipsMove = 1;

extern int ExitTradeOnXCandlesOppositeMove = 20;

int TradingMinutes = 00; // not in use

datetime ThreshHold = 0, TimeNow = 0;
int slipege = 10;// not in use
bool MainRun = false;
//Trades placed at start of candle


// close all at profti paremetes:



input string ExitP; // ***** Exit strategies *****
extern int WaitXCandlesBeforeExit = 1;
extern bool UseMAExit = false;
extern bool UseBreakOutExit = false;
extern bool UseBBExit = false;
extern bool UseDoubleExit = false;
extern bool UseSRExit = false;


extern string ConfrimP; // ***** Confirm entery *****
extern bool ConfirmWithMA = false;
extern bool ConfirmWithHA = false;
extern bool ConfirmWithRSI = false;
extern bool ConfirmWithBB = false;
//cinfirm with BB - dont buy low and sell high




extern string filters; // ***** Trade filters *****

extern int PipsInPreviousCandlesExclude=80;
extern int AmountPreviousCandlesExclude=1;

input int CloseAllPositionsAT = 25;
extern int FirstTradingHour = 0;
extern int LastTradingHour = 24;
extern bool Mon = true;
extern bool Tue = true;
extern bool Wed = true;
extern bool Thur = true;
extern bool Fri = true;

extern bool LongMAFilter = false;
extern int LongMA = 200;


extern bool LongSRFilter = false;
extern int LongSRPeriod = 200;
extern int SlackForSRFilter = 100;

extern bool HourFilter = false;
extern bool DayFilter = false;
extern bool WeekFilter = false;

/* fib filter not in use - same as long SR
extern bool FibFilter = false;
extern int PeriodForFIBFilter = 30;
*/




#include <Open Orders include.mqh>
#include <Manage Open Trades include.mqh>
#include <HA include.mqh>
#include <MA include.mqh>
#include <Range include.mqh>
#include <Double include.mqh>
#include <BB include.mqh>
#include <RSI include.mqh>
//#include <FIB include.mqh>
#include <Pattern include.mqh>


datetime NowTime;
int Day_Of_Week;
string trading_days, other_filters,confim_p,exit_p,sl_p,trail_p,tp_p ;


int OnInit()
{  
// first values of strings:
trading_days = "Trading days are: ";
other_filters = "Other filters are: ";
confim_p = "Confirmation S are: ";
exit_p = "Exit S are: ";
sl_p = "SL mthod is: ";
trail_p = "Trail mthod is: ";
tp_p = "TP P are: ";
string CloseAllText = "";

if (CloseAllPositionsAT <24) CloseAllText = StringConcatenate (" All Positions are closed at: " , CloseAllPositionsAT);

// main S
      if (UseMA) MainS =         "MA";
      if (UseHA) MainS =         "HA";
      if (UseSR) MainS =         "SR";
      if (UseBreakOut) MainS =   "BreakOut";
      if (UseRange) MainS =      "Range";
      if (UseDouble) MainS =     "Double";
      if (UseBB) MainS =         "BB";
//trading day days
      if (Mon) StringAdd (trading_days , "Mon");
      if (Tue) StringAdd (trading_days , ", Tue");
      if (Wed) StringAdd (trading_days , ", Wed");
      if (Thur) StringAdd (trading_days , ", Thur");
      if (Fri) StringAdd (trading_days , ", Fri");
//other filters      
      if (LongMAFilter) StringAdd (other_filters , StringConcatenate(" *LongMAFilter*, period is: ", LongMA ));
      if (LongSRFilter) StringAdd (other_filters ,StringConcatenate( " *LongSRFilter*, period is: ", LongSRPeriod, " ,slack is: " , SlackForSRFilter)); 
      if (HourFilter) StringAdd (other_filters , " *HourFilter* ,");   
      if (DayFilter) StringAdd (other_filters , " *DayFilter* ,");
      if (WeekFilter) StringAdd (other_filters , " *WeekFilter* ,");
//      if (FibFilter) StringAdd (other_filters ,StringConcatenate( " *FibFilter*, period is: ", PeriodForFIBFilter));     
// confirm      
      if (ConfirmWithMA) StringAdd (confim_p , StringConcatenate (" *MA* ,FAST is: " ,FastMA, " ,Slow is: " , SlowMA));
      if (ConfirmWithHA) StringAdd (confim_p , StringConcatenate (" *HA* ,ratio is: " , HA_wik_ratio));
      if (ConfirmWithRSI) StringAdd (confim_p , StringConcatenate(" *RSI* ,period is: " ,RSI_Period, " ,Overext is: " , RSI_OverExtended));
      if (ConfirmWithBB) StringAdd (confim_p , StringConcatenate(" *BB* ,period is: " ,BBPeriod, " ,Deviation is: " , BBDeviation ));
//exit           
      if (UseMAExit) StringAdd (exit_p , StringConcatenate (" *MA* ,FAST is: " ,FastMA, " Slow is: " , SlowMA));
      if(UseBreakOutExit)  StringAdd (exit_p , StringConcatenate (" *Breakout* ,period is: " , PeriodForRange, " ,Breakout pips to confirm: " , ConfirmForBreakout));
      if (UseBBExit) StringAdd (exit_p , StringConcatenate(" *BB* ,period is: " ,BBPeriod, " ,Deviation is: " , BBDeviation ));
      if (UseDoubleExit) StringAdd (exit_p , StringConcatenate(" *Double* ,period is: " ,PeriodForDouble ," ,Wait: " , WaitBetweenCandlesDouble ));
      if (UseSRExit) StringAdd (exit_p , StringConcatenate(" *SR* ,period is: " ,PeriodForSR ," ,Toches: " , TouchesForSR ));
      
//SL    
      if (UseTrailingSL) StringAdd (sl_p , StringConcatenate(" *TrailingSL* ,period is: " , CandlesForTrailing, " ,pips buffer: " , PipsBufferForTrailing));
      else if(UseRange) StringAdd (sl_p , StringConcatenate(" *Range SL* ,period is: " , PeriodForRange, " ,pips buffer: " , SLSlackForRange));
      else if(UseDouble) StringAdd (sl_p , StringConcatenate(" *Double* SL ,period is: " , PeriodForDouble, " ,pips buffer: " , SLSlackForDouble));
      else if(UseSR) StringAdd (sl_p , StringConcatenate(" *SR SL* ,period is: " , PeriodForRange, " ,pips buffer: " , SLSlackForRange));
      else if(UseBreakOut) StringAdd (sl_p , StringConcatenate(" *Breakout SL* ,period is: " , PeriodForRange, " ,pips buffer: " , SLSlackForRange));
      else StringAdd (sl_p , StringConcatenate(" *User fixed SL* ,SL(pips) is: " , UserStopLoss));      
//trail
      if (UseTrailingExit) StringAdd (trail_p , StringConcatenate(" *Cnadles Trail* ,period is: " , CandlesForTrailing, " ,pips buffer: " , PipsBufferForTrailing));
      else StringAdd (trail_p , StringConcatenate(" *User fixed trail* ,Trail (pips) is: " , Trail , " Trail Strat Pips: " , TrailStartPips , " , Trail start cnadles: " ,TrailStartCandles ));
//TP    
      if (!UseTP) tp_p = "not using TP";
      else if(UseRR) StringAdd (tp_p , StringConcatenate(" ,RR TP ,RR is: " , RR_ratio));
      else if(UseRange) StringAdd (tp_p , StringConcatenate(" ,Range TP ,period is: " , PeriodForRange, " ,pips buffer: " , TPSlackForRange));
      else StringAdd (tp_p , StringConcatenate(" ,User fixed TP ,TP(pips) is: " , UserTakeProfit));  
       
      Comment ("Main S : " , MainS , 
      "\nMagicNumber : " , MagicNumber,
      "\nMax Open Trades : " , MaxOpenTrades,
      "\nUserRiskPerTrade : " , UserRiskPerTrade,
      " ,Martinagle multiplier is : ", Martingale,
      " ,Exit On % profit  is : ", ExitOnPrecentProfit,      
      "\nMarubozu Ratio : " , Marubozu_Ratio,
      " ,Doji Ratio : ", Doji_Ratio,  
      "\n" , sl_p,
      "\n" , tp_p,
      "\n" , trail_p,
      " ,Trail start pips : ", TrailStartPips,
      " ,Trail start candles : ", TrailStartCandles,             
      "\nPipsCandlesExclude : ", PipsInPreviousCandlesExclude,
      " ,Amount : ", AmountPreviousCandlesExclude,
      "\nExitTradeOnXPipsMove : ", ExitTradeOnXPipsMove,
      " ,Candles in move : ", CandlesCountForPipsMove,
      "\nExitTradeOnXCandlesOppositeMove : ", ExitTradeOnXCandlesOppositeMove,
      "\nFirstHour : ", FirstTradingHour,
      " ,LastHour : ", LastTradingHour, CloseAllText,     
      "\n", trading_days,
      "\n", other_filters,
      "\n", confim_p,
      "\nWait X Candles before Exit S: ", WaitXCandlesBeforeExit,
      "\n", exit_p);
      
      CurrentRiskPerTrade = UserRiskPerTrade;
      
      rev = StringConcatenate (" Master Trader V43, main strategy is: " , MainS , "Magic number is: " , MagicNumber);

      return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason) 
{  

Comment( " " );

}

//+------------------------------------------------------------------+
//| Start of General functions:                               |
//+------------------------------------------------------------------+

double CalculateLotSize(double SL) //Calculate the size of the position size 
{         
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE); //We get the value of a tick
   double LotSize=(AccountBalance()*CurrentRiskPerTrade/100)/(SL*nTickValue);   //We apply the formula to calculate the position size and assign the value to the variable
//   Print( "LotSize is " , LotSize) ;
   if (Point() == 0.01)
   {
    LotSize = MathRound(LotSize/10);
    Print ("LotSize is: " , LotSize);
    return (LotSize);
    
    }
   return LotSize/10;
}

double CalculatePipSize() //Calculate the size of the position size 
{         
   return (Point*10);
}


void OnTick()
{
//    Comment (" hour  is : "  , TimeHour (TimeCurrent ()));
   if(IsNewCandle()) MainRun = true;
   if (MainRun && OpenOrdersThisPair (Symbol()) > 0  ) manage_open_trade();

     NowTime = TimeCurrent();
     Day_Of_Week = TimeDayOfWeek(NowTime);
     
     if(FirstTradingHour <0) 
     {
             if (MainRun && ((Mon && Day_Of_Week == 1) || (Tue && Day_Of_Week == 2) || (Wed && Day_Of_Week == 3) || (Thur && Day_Of_Week == 4) || (Fri && Day_Of_Week == 5) ))
              {
                 if (OpenOrdersThisPair (Symbol()) < MaxOpenTrades)
                 {       
                      if (check_is_buy ()) PlaceBuyOrder();
                      else if (check_is_sell() ) PlaceSellOrder();
                }
                // else check_open_trade ()
              }
     
     
     
     }
     else     if (MainRun && TimeHour (NowTime)>= FirstTradingHour && TimeHour (NowTime)<=LastTradingHour &&
     ((Mon && Day_Of_Week == 1) || (Tue && Day_Of_Week == 2) || (Wed && Day_Of_Week == 3) || (Thur && Day_Of_Week == 4) || (Fri && Day_Of_Week == 5) ))
              {
                 if (OpenOrdersThisPair (Symbol()) < MaxOpenTrades)
                 {       
                      if (check_is_buy ()) PlaceBuyOrder();
                      else if (check_is_sell() ) PlaceSellOrder();
                }
                // else check_open_trade ()
              }
     if (MainRun && TimeHour (NowTime) == CloseAllPositionsAT ) CloseAllTrades ();
     MainRun = false;
     if (OpenOrdersThisPair (Symbol()) >0) manage_SL();
     CheckTotalProfit();
     

}


