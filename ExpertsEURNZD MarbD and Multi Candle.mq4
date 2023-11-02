//+------------------------------------------------------------------+
//|                         ExpertsEURNZD MarbD and Multi Candle.mq4 |
//|                                                     Roman Geyzer |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+




#property copyright "Roman Geyzer"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property show_inputs



extern int MagicNumber = 1140060;

string rev = "EURNZD_MarbD_+_MultiCandle" ;



extern string TradeP; // ***** Trding parameters ***** 
extern double UserRiskPerTrade=1.5;


double CurrentRiskPerTrade ;

extern string EnterExitP; // ***** Enter or Exit Paremeters *****
extern bool BuyLong = true; 
extern bool SellShort = true; 
extern bool UseOpoositeExit = true;


extern string SLP; // ***** Stop Loss parameters *****
extern bool UseUserSL = false;
extern double UserStopLoss=50;
extern bool UseCandlesSL = true;
extern double SLATR_SlackRatio = 1.5;
extern int SL_CandlesForTrailing=3;


extern string TrailP; // ***** Trail parameters ***** 
extern bool UseMoveToBreakeven = true;
extern double TrailATR_BERatio = 1.5;
extern bool UseATRTrail = true;
extern double ATRTrail_StartMultiplier=4; 
extern double ATRTrail_TrailMultiplier=1.5; 




extern string TPP; // ***** Take Profit parameters ***** 
extern bool UseTP = true;
extern bool UseATRTP = true;
extern double ATRTP_ratio = 8;
extern bool UseUserTP = true;
extern double UserTakeProfit=170; 



//+------------------------------------------------------------------+
//| RSI Include varibales                         |
//+------------------------------------------------------------------+


/*
extern string RSI_P; // ***** RSI parameters *****
extern int RSIPeriod = 14;
extern int RSIBuyMinThresh = 25;
*/

extern string MA_P; // ***** MA parameters *****

extern int FastMA = 25;
extern int SlowMA = 50;
extern double MAsRatio = 45; 
//extern double FastMARatio = 101; 

double pip;
datetime NowTime;

double StopLoss=0;
double TakeProfit=0; 

int ticket;
double Order_size = 0;

double HighestTrail;
double LowestTrail; 

double  CanlesTrailValue ,TrendTrailValue, UserTrailValue ;
double   FinalTrailValue;


int OnInit()
{  
      
      Comment (rev , 
      "\nMagicNumber : " , MagicNumber,
      "\nUserRiskPerTrade : " , UserRiskPerTrade,
      "\nNo Martinagle ",
      "\nOpposite exit used? : " , UseOpoositeExit);
      
      CurrentRiskPerTrade = UserRiskPerTrade;

      pip = Point*10;

      return(INIT_SUCCEEDED);
}


void OnDeinit(const int reason) 
{  

Comment( " " );

}

double CalculateLotSize(double SL) //Calculate the size of the position size 
{         
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE); //We get the value of a tick
   double LotSize=(AccountBalance()*CurrentRiskPerTrade/100)/(SL*nTickValue);   //We apply the formula to calculate the position size and assign the value to the variable
//   Print( "LotSize is " , LotSize) ;
   if (Point() == 0.01)
   {
    LotSize = MathRound(LotSize/10);
    return (LotSize);
    
    }
   return LotSize/10;
}



void OnTick()
{
   if(IsNewCandle())
   {
       NowTime = TimeLocal();
       if (TimeHour (NowTime)>= 2 && TimeHour (NowTime)<=22)
                {
                  if (BuyLong)    
                        if (check_is_buy ())
                        {
                           if (UseOpoositeExit) CloseAllTrades (-1);
                           PlaceBuyOrder();
                        }
                  if (SellShort)
                        if (check_is_sell ())
                        {
                           if (UseOpoositeExit) CloseAllTrades (1);
                           PlaceSellOrder();
                        }
              } 
     }
     if (OpenOrdersThisPair (Symbol()) >0) manage_SL();
}




bool IsNewCandle()
{
   static int BarsOnChart = 0;
   if (Bars == BarsOnChart) return (false);
   BarsOnChart = Bars;
   return (true);

}



int OpenOrdersThisPair(string pair)
{
   int total = 0;
   if (OrdersTotal()>0)
       for (int i=OrdersTotal()-1;i>=0 ; i--)
       {
          if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
               if (OrderSymbol()==pair && OrderMagicNumber() == MagicNumber) total++;

       }
   return (total);
}


int PlaceBuyOrder()//need to update per creteria of SL TP manage trade ext
   {
      
      StopLoss = 5000;
      if (UseCandlesSL) Calculate_CandlesSL (0) ;
      if (UseUserSL)    StopLoss = MathMin(UserStopLoss ,StopLoss) ;
      
       TakeProfit = 0;
       if (UseTP)
       {
          if (UseATRTP) TakeProfit = MathMax(TakeProfit , ATRTP_ratio * iATR(_Symbol , _Period , 14 , 1)/pip);
          if (UseUserTP) TakeProfit=   MathMax(TakeProfit ,UserTakeProfit);
       }    
      
       Print ("Current Risk Per Trade: " ,CurrentRiskPerTrade);       
       Print ("stoploss is: " ,StopLoss); 
       
      Order_size = CalculateLotSize (StopLoss);
      int i=0;
      do 
      { 
       
         if(UseTP && TakeProfit>0 ) ticket = OrderSend (Symbol() , OP_BUY,Order_size, Ask, 5, Ask-StopLoss*pip , Ask+TakeProfit*pip,  rev , MagicNumber, 0,clrGreen);
         else ticket = OrderSend (Symbol() , OP_BUY,Order_size, Ask, 5, Ask-StopLoss*pip , NULL, rev , MagicNumber, 0,clrGreen);
         
         if (ticket<0) Alert( "OrderSend failed with error #" , GetLastError(), " Ask price is:" ,Ask, " ," , rev );
         i++;
         Sleep(1000);
         RefreshRates();
      }
      while (ticket<0 && i<10 );
      
      return ticket;
   }
   
   

int PlaceSellOrder()//need to update per creteria of SL TP manage trade ext
   {       
      StopLoss = 5000;
      if (UseCandlesSL) Calculate_CandlesSL (-1) ;
      if (UseUserSL)    StopLoss = MathMin(UserStopLoss ,StopLoss) ;
      
       TakeProfit = 0;
       if (UseTP)
       {
          if (UseATRTP) TakeProfit = MathMax(TakeProfit , ATRTP_ratio * iATR(_Symbol , _Period , 14 , 1)/pip);
          if (UseUserTP) TakeProfit=   MathMax(TakeProfit ,UserTakeProfit);
       }    
       
      Print ("Current Risk Per Trade: " ,CurrentRiskPerTrade); 
      Print ("stoploss is: " ,StopLoss); 
      
      Order_size = CalculateLotSize (StopLoss);      // create sell order
      int i=0;
      do 
      {
         if(UseTP && TakeProfit>0 ) ticket = OrderSend (Symbol() , OP_SELL,Order_size , Bid , 5, Bid+StopLoss*pip , Bid-TakeProfit*pip, rev  , MagicNumber, 0,clrRed);
         else ticket = OrderSend (Symbol() , OP_SELL,Order_size , Bid , 5, Bid+StopLoss*pip , NULL , rev , MagicNumber, 0,clrRed);
         if (ticket<0)  Alert("OrderSend failed with error #" , GetLastError()," Bid price is:" ,Bid , " ," , rev );
         i++;
         Sleep(1000);
         RefreshRates(); 
      }
      while (ticket<0 && i<10);
      
      return ticket;
   }




void Calculate_CandlesSL (int Dricetion)
{
      if (Dricetion ==0) // Buy
      {
            LowestTrail = Low[iLowest(NULL , 0 , MODE_LOW , SL_CandlesForTrailing , 1)];
            StopLoss = (Ask - LowestTrail + SLATR_SlackRatio*iATR(_Symbol , _Period , 14 , 1))/pip;
            
      }
      else
      {
            HighestTrail = High[iHighest(NULL , 0 , MODE_HIGH , SL_CandlesForTrailing , 1)];
            StopLoss = (HighestTrail - Bid + SLATR_SlackRatio*iATR(_Symbol , _Period , 14 , 1))/pip;
      }

}



bool manage_SL() //check if SL needs to be updated, if yes: call on function update SL
{   
   if(!UseMoveToBreakeven && !UseATRTrail )     return false;
   if(OrdersTotal()>0)    //manage orders:
   {
         for(int i=OrdersTotal()-1; i>=0;i--)
         {
            if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES))
               if(OrderMagicNumber() == MagicNumber)
                 if(OrderSymbol() ==Symbol())
                    if(OrderType() == OP_BUY) //manage buy orders:
                    {
                    
                       if(UseMoveToBreakeven) 
                         if(OrderStopLoss() < OrderOpenPrice())
                             if(OrderClosePrice() >OrderOpenPrice() + TrailATR_BERatio*iATR(_Symbol , _Period , 14 , 1))
                             {
                                    FinalTrailValue = OrderOpenPrice() + 3*pip;
                                    Update_SL(); 
                             }
                       if(UseATRTrail) 
                         if(OrderClosePrice() > OrderOpenPrice() + ATRTrail_StartMultiplier*iATR(_Symbol , _Period , 14 , 1) )
                             if(OrderClosePrice() > OrderStopLoss() + ATRTrail_TrailMultiplier*iATR(_Symbol , _Period , 14 , 1))
                             {
                                    FinalTrailValue = OrderClosePrice() -ATRTrail_TrailMultiplier*iATR(_Symbol , _Period , 14 , 1);
                                    Update_SL(); 
                             }
                             
                     }
                     else // //manage sell orders:  
                     { 
                        if(UseMoveToBreakeven) 
                            if(OrderStopLoss() > OrderOpenPrice())
                                if(OrderClosePrice() < OrderOpenPrice() - TrailATR_BERatio*iATR(_Symbol , _Period , 14 , 1))
                                {
                                       FinalTrailValue = OrderOpenPrice() - 3*pip;
                                       Update_SL(); 
                                }
                                
                         if(UseATRTrail) 
                            if(OrderClosePrice() < OrderOpenPrice() -ATRTrail_StartMultiplier*iATR(_Symbol , _Period , 14 , 1) )
                                if(OrderClosePrice() < OrderStopLoss() - ATRTrail_TrailMultiplier*iATR(_Symbol , _Period , 14 , 1))
                                {
                                       FinalTrailValue = OrderClosePrice() +ATRTrail_TrailMultiplier*iATR(_Symbol , _Period , 14 , 1);
                                       Update_SL(); 
                                }


                     }    
                   
          
                 }
     }
     return true;
}    
                          

void Update_SL() // update SL
{                             
                         if (OrderModify(OrderTicket(),OrderOpenPrice(),FinalTrailValue,OrderTakeProfit() , 0 , clrPurple))   Print( rev + " ,order: "+IntegerToString(ticket) + " updates SL to ", OrderStopLoss() );   
                         else Alert (rev + " ,order: "+IntegerToString(ticket) + " didnt updates SL to ", FinalTrailValue , " ,error: "  , GetLastError());    
}  



    
void CloseAllTrades (int d)
{
           for(int k=OrdersTotal()-1;k>=0;k--)
           {
                if(OrderSelect(k, SELECT_BY_POS)==false) continue;
                if (OrderSymbol()==Symbol() && OrderMagicNumber() == MagicNumber)
                {
                      if ( OrderType() == OP_BUY && d == 1 )  close_open_trade (1 , " opposite trade"); 
                      if ( OrderType() == OP_SELL&& d == -1) close_open_trade (-1 , "opposite trade"); 
                }
                PlaySound("alert.wav");

          }

}



void close_open_trade(int t, string f) // close open trades per user settings
{
     int i=0;
     if (t==1)//close buy  
     {
          do
          {          
                  if (OrderClose(OrderTicket(),OrderLots() ,OrderClosePrice(),10 ,clrRed))
                  {
                       Alert ( "symbol: "+ Symbol() + " closed by: " + f + " , EURUSD H1 Marb");
                       break;                 
                  }
                  else Alert ("symbol: "+ Symbol() + " didnt close by :" + f + ", returnd this error " +IntegerToString(GetLastError()), "Bid price is: " , Bid, "order close price is: " , OrderClosePrice() , rev );
                  if( ! RefreshRates())   Alert ("refresh rates failed"); 
                  i++;
                  Sleep(1000);
          }
          while (i<10 );
     }        
     if (t==-1)//close sell
     {         
         do
         { 
                  if (OrderClose(OrderTicket(),OrderLots() ,OrderClosePrice(),10 ,clrGreen))
                  {
                      Alert ( "symbol: "+ Symbol() + " closed by: " + f + " ,EURUSD H1 Marb");
                      break;
                  }
                  else Alert ( "symbol: "+ Symbol() + " didnt close by :" + f + ", returnd this error " +IntegerToString(GetLastError()),"Ask price is: " , Ask, "order close price is: " , OrderClosePrice() , rev);
                  if( ! RefreshRates())   Alert ("refresh rates failed"); 
                  i++;
                  Sleep(1000);
         }
         while (i<10 );    
     }
}  


bool check_is_buy ()
{  
      if ( Is_MarbouzoD(1))
         if (!HHUHCLLLCD(1))
            if(!ThrClrH4GGG())
               if(!Is_MarbouzoH4(1))
                  if(!OutH4(1))
                     if(!GRG() && !GRR() && !RGR())
                        if(!HHUHCLLLC(1))
                           if(!InBar(1))
                              return(true);//PlaceBuyOrder();
   return(false);
}    


bool check_is_sell ()
{ 

      if (!Is_MarbouzoD(1))
         if (HHUHCLLLCD(1))
            if(!OutD(1))
               if(!OutH4(1))
                  if(!ThrClrH4RRR())
                     if(!RGR() && !GRR())
                        if(!HHUHCLLLC(1))
                           if(((iMA(NULL , PERIOD_CURRENT, FastMA,0,0 , 0,1) / iMA(NULL , PERIOD_CURRENT, SlowMA,0,0 , 0,1))-1)*10000>MAsRatio) 
                              if(Candle_color(1) ==-1)
                                 return(true);//PlaceSellOrder();
   return(false);
}    






/*******************************************************************************************************************************
//+------------------------------------------------------------------+
//| Candlepattern check help functions:                     |
//+------------------------------------------------------------------+
********************************************************************************************************************************/






int Candle_color (int candle_i)
{
   if (Close [candle_i] < Open[candle_i]) return (-1);//red
   if (Close [candle_i] > Open[candle_i]) return (1); //green
   return (0); // no body (open==close)
}


double Body_Size (int candle_i)
{
   return (MathAbs( (Close [candle_i] - Open[candle_i] )));
}


double Upper_Wik_Size (int candle_i)
{
   if (Candle_color (candle_i) ==-1) return ( (High[candle_i] - Open [candle_i]));
   else return ( (High [candle_i] - Close[candle_i] ));
}


double Lower_Wik_Size (int candle_i)
{
   if (Candle_color (candle_i) ==-1) return ( (Close[candle_i] - Low [candle_i]));
   else return ( (Open [candle_i] - Low[candle_i] ));
}


double Upper_wik_ratio (int candle_i)
{
   if (Upper_Wik_Size (candle_i) == 0 ) return (10);
   return (Body_Size (candle_i) / Upper_Wik_Size (candle_i));
}


double Lower_wik_ratio (int candle_i)
{   
   if (Lower_Wik_Size (candle_i) == 0 ) return (10);
   return (Body_Size (candle_i) / Lower_Wik_Size (candle_i));
}


double wik_ratio (int candle_i)
{
   if (Upper_Wik_Size (candle_i) == 0 &&  Lower_Wik_Size (candle_i) == 0  ) return (10); // no wiks
   return ( Body_Size(candle_i)  / (Upper_Wik_Size (candle_i) + Lower_Wik_Size (candle_i)));
}

bool Is_Marbouzo (int i)
{
         if (Candle_color(i)== 0) return false;
        if (MathMax(Upper_wik_ratio(i),Lower_wik_ratio(i))>=4 && wik_ratio(i)>2.5) return true;
        return false;
}



bool NotLLLC()
{
     if (Close[1] < Close[2] && Low[1] < Low[2])
     {
         return false; 
     }
     return true;
}

bool InvHam(int i)
{
     if (wik_ratio(i) > 0.25) return false;
     if (Lower_Wik_Size(1) == 0) return true;
     if (Upper_Wik_Size(1) / Lower_Wik_Size(1)  >2.5 ) return true;

     return false;
}



bool Not2Marb()
{
     if (Is_Marbouzo(1) && Is_Marbouzo(2)) return false;
     return true;
}



bool GRG()
{
     if (Candle_color(3) == 1 && Candle_color(2) == -1 && Candle_color(1) == 1) return true;
     return false;
}

bool RGR()
{
     if (Candle_color(3) == -1 && Candle_color(2) == 1 && Candle_color(1) == -1) return true;
     return false;
}

bool RRR()
{
     if (Candle_color(3) == -1 && Candle_color(2) == -1 && Candle_color(1) == -1) return true;
     return false;
}



bool GRR()
{
     if (Candle_color(3) == 1 && Candle_color(2) == -1 && Candle_color(1) == -1) return true;
     return false;
}




bool HHUHCLLLC(int i)
{
   if (Candle_color(i) == 1)
      if (Close[1] > Close[2] && High[1] > High[2])
         return true;
   if (Candle_color(i) == -1)
      if (Close[1] < Close[2] && Low[1] < Low[2])
         return true;
   return false;
}


bool InBar(int i)
{
   if (iHigh(_Symbol , PERIOD_D1 ,  1) < iHigh(_Symbol , PERIOD_D1 ,  2) && iLow(_Symbol , PERIOD_D1 ,  1) > iLow(_Symbol , PERIOD_D1 ,  2))
         return true;
   return false;
}



bool Out(int i)
{
   if (High[1] > High[2] && Low[1] < Low[2])
         return true;
   return false;
}




/*******************************************************************************************************************************
//+------------------------------------------------------------------+
//| H4                                 |
//+------------------------------------------------------------------+
********************************************************************************************************************************/

int Candle_colorH4 (int candle_i)
{
   if (iClose(_Symbol , PERIOD_H4 ,  candle_i) < iOpen(_Symbol , PERIOD_H4 ,  candle_i)) return (-1);//red
   if (iClose(_Symbol , PERIOD_H4 ,  candle_i) > iOpen(_Symbol , PERIOD_H4 ,  candle_i)) return (1); //green
   return (0); // no body (open==close)
}


double Body_SizeH4 (int candle_i)
{
   return (MathAbs( (iClose(_Symbol , PERIOD_H4 ,  candle_i) - iOpen(_Symbol , PERIOD_H4 ,  candle_i) )));
}


double Upper_Wik_SizeH4 (int candle_i)
{
   if (Candle_colorH4 (candle_i) ==-1) return ( (iHigh(_Symbol , PERIOD_H4 ,  candle_i) - iOpen(_Symbol , PERIOD_H4 ,  candle_i)));
   else return ( (iHigh(_Symbol , PERIOD_H4 ,  candle_i) - iClose(_Symbol , PERIOD_H4 ,  candle_i) ));
}


double Lower_Wik_SizeH4 (int candle_i)
{
   if (Candle_colorH4 (candle_i) ==-1) return ( (iClose(_Symbol , PERIOD_H4 ,  candle_i) - iLow(_Symbol , PERIOD_H4 ,  candle_i)));
   else return ( (iOpen(_Symbol , PERIOD_H4 ,  candle_i) - iLow(_Symbol , PERIOD_H4 ,  candle_i) ));
}


double Upper_wik_ratioH4 (int candle_i)
{
   if (Upper_Wik_SizeH4 (candle_i) == 0 ) return (10);
   return (Body_SizeH4 (candle_i) / Upper_Wik_SizeH4 (candle_i));
}


double Lower_wik_ratioH4 (int candle_i)
{   
   if (Lower_Wik_SizeH4 (candle_i) == 0 ) return (10);
   return (Body_SizeH4 (candle_i) / Lower_Wik_SizeH4 (candle_i));
}


double wik_ratioH4 (int candle_i)
{
   if (Upper_Wik_SizeH4 (candle_i) == 0 &&  Lower_Wik_SizeH4 (candle_i) == 0  ) return (10); // no wiks
   return ( Body_SizeH4(candle_i)  / (Upper_Wik_SizeH4 (candle_i) + Lower_Wik_SizeH4 (candle_i)));
}

bool Is_MarbouzoH4 (int i)
{
         if (Candle_colorH4(i)== 0) return false;
        if (MathMax(Upper_wik_ratioH4(i),Lower_wik_ratioH4(i))>=4 && wik_ratioH4(i)>2.5) return true;
        return false;
}

bool NotGGRH4()
{
     if (Candle_colorH4(3) == 1 && Candle_colorH4(2) == 1 )
     {
         return false; 
     }
     return true;
}



bool ThrClrH4GRR()
{
   if (Candle_colorH4(3) == 1 && Candle_colorH4(2) == -1 && Candle_colorH4(1) == -1 ) return true;
   return false;

}



bool ThrClrH4RGG()
{
   if (Candle_colorH4(3) == -1 && Candle_colorH4(2) == 1 && Candle_colorH4(1) == 1 ) return true;
   return false;


}




bool ThrClrH4RGR()
{
   if (Candle_colorH4(3) == -1 && Candle_colorH4(2) == 1 && Candle_colorH4(1) == -1 ) return true;
   return false;


}

bool ThrClrH4RRG()
{
   if (Candle_colorH4(3) == -1 && Candle_colorH4(2) == -1 && Candle_colorH4(1) == 1 ) return true;
   return false;


}

bool ThrClrH4RRR()
{
   if (Candle_colorH4(3) == -1 && Candle_colorH4(2) == -1 && Candle_colorH4(1) == -1 ) return true;
   return false;
}

bool ThrClrH4GGG()
{
   if (Candle_colorH4(3) == 1 && Candle_colorH4(2) == 1 && Candle_colorH4(1) == 1 ) return true;
   return false;
}


bool HamH4(int i)
{
     if (wik_ratioH4(i) > 0.25) return false;
     if (Upper_Wik_SizeH4(i) == 0) return true;
     if (Lower_Wik_SizeH4(i) /Upper_Wik_SizeH4(i) >2.5 ) return true;

     return false;
}



bool HHUHCLLLCH4(int i)
{
   if (Candle_colorH4(i) == 1)
      if (iClose(_Symbol , PERIOD_H4 ,  1) > iClose(_Symbol , PERIOD_H4 ,  2) && iHigh(_Symbol , PERIOD_H4 ,  1) > iHigh(_Symbol , PERIOD_H4 ,  2))
         return true;
   if (Candle_colorH4(i) == -1)
      if (iClose(_Symbol , PERIOD_H4 ,  1) < iClose(_Symbol , PERIOD_H4 ,  2) && iLow(_Symbol , PERIOD_H4 ,  1) < iLow(_Symbol , PERIOD_H4 ,  2))
         return true;
   return false;
}



bool OutH4(int i)
{
   if (iHigh(_Symbol , PERIOD_H4 ,  1) > iHigh(_Symbol , PERIOD_H4 ,  2) && iLow(_Symbol , PERIOD_H4 ,  1) < iLow(_Symbol , PERIOD_H4 ,  2))
         return true;
   return false;
}


bool InBarH4(int i)
{
   if (iHigh(_Symbol , PERIOD_H4 ,  1) < iHigh(_Symbol , PERIOD_H4 ,  2) && iLow(_Symbol , PERIOD_H4 ,  1) > iLow(_Symbol , PERIOD_H4 ,  2))
         return true;
   return false;
}



/*******************************************************************************************************************************
//+------------------------------------------------------------------+
//| D                               |
//+------------------------------------------------------------------+
********************************************************************************************************************************/

int Candle_colorD (int candle_i)
{
   if (iClose(_Symbol , PERIOD_D1 ,  candle_i) < iOpen(_Symbol , PERIOD_D1 ,  candle_i)) return (-1);//red
   if (iClose(_Symbol , PERIOD_D1 ,  candle_i) > iOpen(_Symbol , PERIOD_D1 ,  candle_i)) return (1); //green
   return (0); // no body (open==close)
}


double Body_SizeD (int candle_i)
{
   return (MathAbs( (iClose(_Symbol , PERIOD_D1 ,  candle_i) - iOpen(_Symbol , PERIOD_D1 ,  candle_i) )));
}


double Upper_Wik_SizeD (int candle_i)
{
   if (Candle_colorD (candle_i) ==-1) return ( (iHigh(_Symbol , PERIOD_D1 ,  candle_i) - iOpen(_Symbol , PERIOD_D1 ,  candle_i)));
   else return ( (iHigh(_Symbol , PERIOD_D1 ,  candle_i) - iClose(_Symbol , PERIOD_D1 ,  candle_i) ));
}


double Lower_Wik_SizeD (int candle_i)
{
   if (Candle_colorD (candle_i) ==-1) return ( (iClose(_Symbol , PERIOD_D1 ,  candle_i) - iLow(_Symbol , PERIOD_D1 ,  candle_i)));
   else return ( (iOpen(_Symbol , PERIOD_D1 ,  candle_i) - iLow(_Symbol , PERIOD_D1 ,  candle_i) ));
}


double Upper_wik_ratioD (int candle_i)
{
   if (Upper_Wik_SizeD (candle_i) == 0 ) return (10);
   return (Body_SizeD (candle_i) / Upper_Wik_SizeD (candle_i));
}


double Lower_wik_ratioD (int candle_i)
{   
   if (Lower_Wik_SizeD (candle_i) == 0 ) return (10);
   return (Body_SizeD (candle_i) / Lower_Wik_SizeD (candle_i));
}


double wik_ratioD (int candle_i)
{
   if (Upper_Wik_SizeD (candle_i) == 0 &&  Lower_Wik_SizeD (candle_i) == 0  ) return (10); // no wiks
   return ( Body_SizeD(candle_i)  / (Upper_Wik_SizeD (candle_i) + Lower_Wik_SizeD (candle_i)));
}



bool Is_MarbouzoD (int i)
{
         if (Candle_colorD(i)== 0) return false;
        if (MathMax(Upper_wik_ratioD(i),Lower_wik_ratioD(i))>=4 && wik_ratioD(i)>2.5) return true;
        return false;
}

bool InvHamD(int i)
{
     if (wik_ratioD(i) > 0.25) return false;
     if (Lower_Wik_SizeD(1) == 0) return true;
     if (Upper_Wik_SizeD(1) / Lower_Wik_SizeD(1)  >2.5 ) return true;

     return false;
}


bool HHUHCLLLCD(int i)
{
   if (Candle_colorD(i) == 1)
      if (iClose(_Symbol , PERIOD_D1 ,  1) > iClose(_Symbol , PERIOD_D1 ,  2) && iHigh(_Symbol , PERIOD_D1 ,  1) > iHigh(_Symbol , PERIOD_D1 ,  2))
         return true;
   if (Candle_colorD(i) == -1)
      if (iClose(_Symbol , PERIOD_D1 ,  1) < iClose(_Symbol , PERIOD_D1 ,  2) && iLow(_Symbol , PERIOD_D1 ,  1) < iLow(_Symbol , PERIOD_D1 ,  2))
         return true;
   return false;
}

bool OutD(int i)
{
   if (iHigh(_Symbol , PERIOD_D1 ,  1) > iHigh(_Symbol , PERIOD_D1 ,  2) && iLow(_Symbol , PERIOD_D1 ,  1) < iLow(_Symbol , PERIOD_D1 ,  2))
         return true;
   return false;
}


bool InBarD(int i)
{
   if (iHigh(_Symbol , PERIOD_D1 ,  1) < iHigh(_Symbol , PERIOD_D1 ,  2) && iLow(_Symbol , PERIOD_D1 ,  1) > iLow(_Symbol , PERIOD_D1 ,  2))
         return true;
   return false;
}

