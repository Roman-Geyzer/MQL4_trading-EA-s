//+------------------------------------------------------------------+
//|                                                 Testing code.mq4 |
//|                                                     Roman Geyzer |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Roman Geyzer"
#property link      ""
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+


//Percentage of available balance to risk in each individual trade
extern double MaxRiskPerTrade=1; //% of balance to risk in one trade
extern int StopLoss=100; //Stop Loss in pips (thoretical)
 
//We define the function to calculate the position size and return the lot to order
//Only parameter the Stop Loss, it will return a double
double CalculateLotSize(double SL) //Calculate the size of the position size 
{         
   double LotSize=0; //We get the value of a tick
   double nTickValue=MarketInfo(Symbol(),MODE_TICKVALUE);
//If the digits are 3 or 5 we normalize multiplying by 10
   if(Digits==3 || Digits==5){
      nTickValue=nTickValue*10;
   }
   //We apply the formula to calculate the position size and assign the value to the variable
   LotSize=(AccountBalance()*MaxRiskPerTrade/100)/(SL*nTickValue);
   return LotSize;
}
 
int OnInit()
{
   return(INIT_SUCCEEDED);
}
 
void OnDeinit(const int reason)
{
 
}
 
void OnTick()
{
   //We print the position size in lots
   Print("Position size in lots? ",CalculateLotSize(StopLoss));
}



