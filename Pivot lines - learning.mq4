//+------------------------------------------------------------------+
//|                                       Pivot lines - learning.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright ""
#property link      ""
#property version   "1.00"
#property strict
#property indicator_chart_window
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                       Pivot lines - learning.mq4 |
//|                                                                  |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+

extern int pivot_timeframe=43200;

double C, H, L, P, R1, R2, S1, S2 ;

void DeleteLines()
   {
      ObjectDelete("Pivot Line");
      ObjectDelete("S1 Line");
      ObjectDelete("S2 Line");
      ObjectDelete("R1 Line");
      ObjectDelete("R2 Line");

   }

void CalculatePivot()
   {
      C=iClose(NULL, pivot_timeframe,1);
      H=iHigh(NULL, pivot_timeframe,1);
      L=iLow(NULL, pivot_timeframe,1);
      P= (C+H+L)/3;
      R2= P+H-L;
      R1= 2*P-L;
      S1= 2*P-H;
      S2= P-H+L;
      
   }

void DrawLines()
   {
      ObjectCreate("Pivot Line", OBJ_HLINE , 0 , 0 , P);
      ObjectSet ("Pivot Line", OBJPROP_COLOR, Green);
      ObjectCreate("S1 Line", OBJ_HLINE , 0 , 0 , S1);
      ObjectSet ("S1 Line", OBJPROP_COLOR, Red);
      ObjectCreate("S2 Line", OBJ_HLINE , 0 , 0 , S2);
      ObjectSet ("S2 Line", OBJPROP_COLOR, Red);
      ObjectCreate("R1 Line", OBJ_HLINE , 0 , 0 , R1);
      ObjectSet ("R1 Line", OBJPROP_COLOR, DodgerBlue);
      ObjectCreate("R2 Line", OBJ_HLINE , 0 , 0 , R2);
      ObjectSet ("R2 Line", OBJPROP_COLOR, DodgerBlue);
      
   }



int OnInit()
   {
      DeleteLines();
      CalculatePivot();
      Print("Closing price for the prev month is ", C );
      Print("Highes price for the prev month is ", H );
      Print("Lowest price for the prev month is ", L );
      Print("The Pivot value is ", P );
      
      return(INIT_SUCCEEDED);
    }


void deinit()
   {
      DeleteLines();
   }
   
 
   int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

   DrawLines();
   return(rates_total);
  }           
              




