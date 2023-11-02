//+------------------------------------------------------------------+
//|                                      MA Crossover EA - learn.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Declaration of variables                               |
//+------------------------------------------------------------------+
extern int MagicNumber = 111111;//index for finding specific trade
extern int FastMA_period = 20;
extern int SlowMA_period = 50;
extern int MA_Mtd = 0; // which method for average will be used
extern int takeprofit_pips = 500;
extern int stoploss_pips = 500;
extern double oredersize = 0.5;// lot size for each trade
extern int mins_per_trade = 60;//to set how many minutes between trades

double current_FASTMA,current_SLOWMA, prev_FASTMA, prev_SLOWMA;

bool Free_to_trade = True;// determins if can or not trade

int Total_Mins_Diff, Mins_Diff, Hours_Diff;

datetime Order_Date = D'2001.01.01';


//+------------------------------------------------------------------+
//| custom functions                               |
//+------------------------------------------------------------------+

void PlaceBuyOrder()
   {
      double takeprofit = (Ask + takeprofit_pips*Point );
      double stoploss = (Ask - stoploss_pips*Point );
      // create buy order
      int ticket = OrderSend (Symbol() , OP_BUY, oredersize , Ask, 3, stoploss , takeprofit, "My Order", MagicNumber, 0,clrGreen);
      //the following loop check
      if (ticket<0)
         {
            Print("OrderSend failed with error #" , GetLastError());
         }
      else
         {
            Print("OrderSend placed succedfuly");
            Free_to_trade = False;
            Order_Date = TimeCurrent();
         }
      
   }


void PlaceSellOrder()
   {
      double takeprofit = (Bid - takeprofit_pips*Point );
      double stoploss = (Bid + stoploss_pips*Point );
      // create buy order
      int ticket = OrderSend (Symbol() , OP_SELL,oredersize , Bid , 3, stoploss , takeprofit, "My Order", MagicNumber, 0,clrRed);
      //the following loop check
      if (ticket<0)
         {
            Print("OrderSend failed with error #" , GetLastError());
         }
      else
         {
            Print("OrderSend placed succedfuly");
            Free_to_trade = False;
            Order_Date = TimeCurrent();
         }
      
   }



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      current_FASTMA = iMA(NULL , 0, FastMA_period,0,MA_Mtd , PRICE_MEDIAN,0);
      prev_FASTMA = iMA(NULL , 0, FastMA_period,0,MA_Mtd , PRICE_MEDIAN,1);// thr fast MA value from last
      
      current_SLOWMA = iMA(NULL , 0, SlowMA_period,0,MA_Mtd , PRICE_MEDIAN,0);
      prev_SLOWMA = iMA(NULL , 0, SlowMA_period,0,MA_Mtd , PRICE_MEDIAN,1);// thr slow MA value from last
      
      // following coed: calculate mintues from last trade
      
      Mins_Diff = ( TimeMinute (TimeCurrent ()) - TimeMinute (Order_Date));
      if (Mins_Diff <0)
         Mins_Diff = Mins_Diff +60;
         
      Hours_Diff = ( TimeHour (TimeCurrent ()) - TimeHour (Order_Date));
      if (Hours_Diff <0)
         Hours_Diff = Hours_Diff +24;
      
      
      Total_Mins_Diff = Hours_Diff * 60 + Mins_Diff;
      
      if (Total_Mins_Diff > mins_per_trade ) // check if enogh time has passed : can we trade?
         Free_to_trade = true;
         
      if (current_FASTMA > current_SLOWMA && Free_to_trade )
         if (prev_FASTMA < prev_SLOWMA)
            PlaceBuyOrder ();
      
      if (current_FASTMA < current_SLOWMA && Free_to_trade )
         if (prev_FASTMA > prev_SLOWMA)
            PlaceSellOrder ();
   
  }
//+------------------------------------------------------------------+
