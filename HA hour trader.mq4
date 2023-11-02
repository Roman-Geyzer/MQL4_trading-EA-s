//+------------------------------------------------------------------+
//|                                       Heiken Ashi day Trader.mq4 |
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

extern int MagicNumber = 123456;//index for finding specific trade
extern double MaxRiskPerTrade=1; //% of balance to risk in one trade
extern int StopLoss=50; 
extern int Trail=30; 
extern int place_trades_time = 00;//Trades placed at te begining of the hour
extern int FastMA = 5;
extern int SlowMA = 21;




double HA_High [16], HA_Low[16] , HA_Open[16], HA_Close[16];

double Order_size = 0;
int ticket;

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


double CalculateLotSize(double SL) //Calculate the size of the position size 
{         
   double LotSize=0; //We get the value of a tick
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE); 
   //We apply the formula to calculate the position size and assign the value to the variable
   LotSize=(AccountBalance()*MaxRiskPerTrade/100)/(SL*nTickValue);
   return LotSize/10;
}

double CalculatePipSize() //Calculate the size of the position size 
{         
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
   return nTickValue/10000;
}

int PlaceBuyOrder()
   {
      Order_size = CalculateLotSize (StopLoss);
      ticket = OrderSend (Symbol() , OP_BUY,Order_size, Ask, 3, Ask-StopLoss*CalculatePipSize() , NULL, "My Order", MagicNumber, 0,clrGreen);
      //the following loop check
      if (ticket<0)
            Print("OrderSend failed with error #" , GetLastError());

      return ticket;
   }
   
   

int PlaceSellOrder()
   {
      Order_size = CalculateLotSize (StopLoss);

      // create buy order
      ticket = OrderSend (Symbol() , OP_SELL,Order_size , Bid , 3, Bid+StopLoss*CalculatePipSize() , NULL, "My Order", MagicNumber, 0,clrRed);
      //the following loop check
      if (ticket<0)
            Print("OrderSend failed with error #" , GetLastError());

      return ticket;
   }



bool check_is_buy ()
{
/*
      current_FASTMA = iMA(NULL , 0, FastMA_period,0,MA_Mtd , PRICE_MEDIAN,0);
      prev_FASTMA = iMA(NULL , 0, FastMA_period,0,MA_Mtd , PRICE_MEDIAN,1);// thr fast MA value from last
*/           

      HA_Open [15] = (Open[16] + Close[16])/2 ;
      HA_Close[15] = (Open[15] + High[15] + Low[15] + Close[15]) / 4;
      HA_High [15] = MathMax(High[15], MathMax(HA_Open[15], HA_Close[15]));
      HA_Low[15] = MathMin(Low[15], MathMin(HA_Open[15], HA_Close[15]));
      
      for (int i=14 ; i>=0 ; i--)
      {
         HA_Open [i] = (HA_Open[i+1] + HA_Close[i+1])/2 ;
         HA_Close[i] = (Open[i] + High[i] + Low[i] + Close[i]) / 4;
         HA_High [i] = MathMax(High[i], MathMax(HA_Open[i], HA_Close[i]));
         HA_Low[i] = MathMin(Low[i], MathMin(HA_Open[i], HA_Close[i]));
      }    
      if ( iMA(NULL , 0, FastMA,0,1 , 0,0) > iMA(NULL , 0, SlowMA,0,1 , 0,0)) // added check for MA for trend // HA_Open[1] < HA_Close[1] &&
          return (  HA_Open[1]<HA_Close[1]);
      else return (false);
}    


bool check_is_sell ()
{
 
  
      HA_Open [15] = (Open[16] + Close[16])/2 ;
      HA_Close[15] = (Open[15] + High[15] + Low[15] + Close[15]) / 4 ;
      HA_High [15] = MathMax(High[15], MathMax(HA_Open[15], HA_Close[15]));
      HA_Low[15] = MathMin(Low[15], MathMin(HA_Open[15], HA_Close[15]));
      
      for (int i= 14 ; i>=0 ; i--)
      {
         HA_Open [i] = (HA_Open[i+1] + HA_Close[i+1])/2 ;
         HA_Close[i] = (Open[i] + High[i] + Low[i] + Close[i]) / 4 ;
         HA_High [i] = MathMax(High[i], MathMax(HA_Open[i], HA_Close[i]));
         HA_Low[i] = MathMin(Low[i], MathMin(HA_Open[i], HA_Close[i]));
        
      
      }
      
      
       if( iMA(NULL , 0, FastMA,0,1 , 0,0) < iMA(NULL , 0, SlowMA,0,1 , 0,0))//HA_Open[1] > HA_Close[1]&& 
       {
            return (  HA_Open[1]>HA_Close[1]);
       }
       else return (false);
        
     
}         
      
      
void check_open_trade() // check vurrent open and closes if neccesery
{
      HA_Open [15] = (Open[16] + Close[16])/2 ;
      HA_Close[15] = (Open[15] + High[15] + Low[15] + Close[15]) / 4;
      HA_High [15] = MathMax(High[15], MathMax(HA_Open[15], HA_Close[15]));
      HA_Low[15] = MathMin(Low[15], MathMin(HA_Open[15], HA_Close[15]));
      
      for (int i= 14 ; i>=0; i--)
      {
         HA_Open [i] = (HA_Open[i+1] + HA_Close[i+1])/2 ;
         HA_Close[i] = (Open[i] + High[i] + Low[i] + Close[i]) / 4;
         HA_High [i] = MathMax(High[i], MathMax(HA_Open[i], HA_Close[i]));
         HA_Low[i] = MathMin(Low[i], MathMin(HA_Open[i], HA_Close[i]));    
      }
      
   if(OrderSelect(ticket, SELECT_BY_TICKET))    // select current trade for OrderType function
   {
     if (OrderType()== 0 ) // check if Buy
       {
            if( HA_Open[1] >= HA_Close[1] ) 
            {
               if (Close[1] < High[2])
               {
                  if (OrderClose(ticket,OrderLots() ,Bid,3 ,clrRed)) // run close and check if not run
                  {
                     MessageBox ( "order "+IntegerToString(ticket)+ " closed ");            
                  }
                  else MessageBox ( "order "+ IntegerToString(ticket)+ " didnt close, returnd this error " + IntegerToString(GetLastError()));
               }
         }
       }
   
     else // must be sell
     {
        if (Close[1] > Low[2])
        {
              if( HA_Open[1] <= HA_Close[1] )
              {

                 if (OrderClose(ticket,OrderLots() ,Ask,3 ,clrGreen)) // run close and check if not run
                 {
                    MessageBox ( "order "+IntegerToString(ticket) + " closed ");
                 }
              else MessageBox ( "order " + IntegerToString(ticket) + " didnt close, returnd this error " +IntegerToString(GetLastError()));
              }
         }
     }
   }     

}


void manage_open_trade() // update SL
{
   //manage buy orders:
   if(OrdersTotal()>0)
   {
         for(int b=OrdersTotal()-1; b>=0;b--)
         {
            if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
               if(OrderMagicNumber() == MagicNumber)
                 if(OrderSymbol() ==Symbol())
                    if(OrderType() == OP_BUY)
                        if(OrderStopLoss()<Bid-Trail*CalculatePipSize())
                            if (OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Trail*CalculatePipSize(),NULL , 0 , CLR_NONE))
                                Print ( "order "+IntegerToString(ticket) + " updates SL to ", OrderStopLoss());
         }   
   //manage Sell orders:   
       for(int s=OrdersTotal()-1; s>=0;s--)
        {
            if(OrderSelect(s,SELECT_BY_POS,MODE_TRADES))
              if(OrderMagicNumber() == MagicNumber)
                 if(OrderSymbol() ==Symbol())
                    if(OrderType() == OP_SELL)
                       if(OrderStopLoss()>Ask+Trail*CalculatePipSize())
                          if (OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Trail*CalculatePipSize(),NULL , 0 , CLR_NONE))
                              Print ( "order "+IntegerToString(ticket) + " updates SL to ", OrderStopLoss());
          }
    }
}  


int OpenOrdersThisPair(string pair)
{
   int total = 0;
   if (OrdersTotal()>0)
       for (int i=OrdersTotal()-1;i>=0 ; i--)
       {
          if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
               if (OrderSymbol()==pair) total++;

       }
   return (total);
}


void OnTick()
{
    if (TimeMinute(TimeCurrent())== place_trades_time)
    {
        if (OpenOrdersThisPair (Symbol()) ==0)
        {       
              if (check_is_buy ())
                 ticket = PlaceBuyOrder();
              else if (check_is_sell() )
                  ticket = PlaceSellOrder();
        }
        else check_open_trade ();
        
     }
    if (OpenOrdersThisPair (Symbol()) ==1)
    
          manage_open_trade();

}

