//+------------------------------------------------------------------+
//|                                                       MACross.mq5|
//|                                   Copyright 2024, Frank Erdtmann |
//+------------------------------------------------------------------+
#property strict
#property version "1.01"
#property script_show_inputs

input int magicNB = 2605;
input int FASTMA = 10;
input int SLOWMA = 20;
input double DIFFERENCE = 0.00001;
input double SL = 30;
input double TP = 60;
input double LOT = 0.1;

long chart_id;
int openOrderID;
// In MQL5, the `int` data type is used to declare integer variables. The line `int openOrderID;` declares a variable named `openOrderID` of type `int`. This variable is intended to store an integer value, which could be used to represent an order ID for a trade or position in a trading algorithm.
// 
// Here's a simple example of how you might use `openOrderID` in an MQL5 script:
// 

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
/*
int OnInit()
  {
   // Example: Opening a buy order and storing its ticket number
   double lotSize = 0.1; // Lot size for the order
   double stopLoss = 0;  // Stop loss level
   double takeProfit = 0; // Take profit level
   int slippage = 3;     // Slippage in points
   string symbol = _Symbol; // Current symbol

   // Open a buy order
   openOrderID = OrderSend(symbol, OP_BUY, lotSize, Ask, slippage, stopLoss, takeProfit, "My Buy Order", 0, 0, clrGreen);

   // Check if the order was successfully opened
   if(openOrderID < 0)
     {
      Print("OrderSend failed with error #", GetLastError());
      return INIT_FAILED;
     }
   else
     {
      Print("Order opened successfully. Order ID: ", openOrderID);
     }

   return INIT_SUCCEEDED;
  }
*/
//+------------------------------------------------------------------+

// 
// In this example:
// 
// - We declare `openOrderID` to store the ticket number of the order we are going to open.
// - We attempt to open a buy order using `OrderSend()`.
// - If the order is successfully opened, `OrderSend()` returns the ticket number, which is stored in `openOrderID`.
// - If the order fails to open, `OrderSend()` returns a negative value, and we print an error message using `GetLastError()`.
// 
// This is a basic example to illustrate how you might use an integer variable to track an order ID in an MQL5 script. Depending on your trading strategy, you may need to add more logic to handle different order types, error checking, and order management.
// 

double minSL;   

enum BuySell {
   BUY,
   SELL
};

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   chart_id=ChartID();
   minSL = SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL);
     
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){
   
}
  
double FastMACurr(){
   int ma = iMA(NULL,0,FASTMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1]; 
   CopyBuffer(ma,0,0,1,res);
   return res[0];
}  

double FastMAPrev(){
   int ma = iMA(NULL,0,FASTMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1];
   CopyBuffer(ma,0,1,1,res);
   return res[0];
}  

double SlowMACurr(){
   int ma = iMA(NULL,0,SLOWMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1];
   CopyBuffer(ma,0,0,1,res);
   return res[0];
}  

double SlowMAPrev(){
   int ma = iMA(NULL,0,SLOWMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1];
   CopyBuffer(ma,0,1,1,res);
   return res[0];
}  
  
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(){
   
   datetime BarTimes[3];
   
   CopyTime(NULL,0,0,3,BarTimes);
   
   Print("#1: "+BarTimes[0]);
   Print("#2: "+BarTimes[1]);
   Print("#3: "+BarTimes[2]);
   
   uint ticket;
   
   // Verkauf
   if(Sell()){         
      // Sell Signal
      
      // Wenn keine Sell Order vorhanden
      if(!CheckOpenSellOrder()){
         // Wenn Buy Order vorhanden
         if(CheckOpenBuyOrder()){
            // SChließe Buy Order
            CloseBuyOrder(OrderGetInteger(ORDER_TICKET),OrderGetDouble(ORDER_VOLUME_INITIAL),OrderGetDouble(ORDER_PRICE_CURRENT));
            // Öffne Sell Order
            SellOrder();
         // Wenn keine Buy Order vorhanden
         }else{
            // Öffne Sell Order
            SellOrder();
         }
      }
   }
   // Kauf
   if(Buy()){
      // Buy Signal
      
      // Wenn keine Buy Order vorhanden
      if(!CheckOpenBuyOrder()){
         // Wenn Sell Order vorhanden
         if(CheckOpenSellOrder()){
            // Schließe Sell Order
            CloseSellOrder(OrderGetInteger(ORDER_TICKET),OrderGetDouble(ORDER_VOLUME_INITIAL),OrderGetDouble(ORDER_PRICE_CURRENT));
            // Öffne Buy Order
            BuyOrder();       
         // Wenn keine Sell Order vorhanden  
         }else{
            // Öffne Buy Order
            BuyOrder();
         }
      }
   }
}

// Prüfen ob Kauf Signal
bool Buy(){
   bool buy = false;
   if(NormalizeDouble(SlowMAPrev(),_Digits) >= NormalizeDouble(FastMAPrev(),_Digits)
      && NormalizeDouble(SlowMACurr(),_Digits) < NormalizeDouble(FastMACurr(),_Digits) 
      && (MathAbs(FastMACurr() - SlowMACurr()) > DIFFERENCE)){
      buy = true;     
   }
   return buy;
}

// Prüfen ob Verkauf Signal
bool Sell(){
   bool sell = false;
   if(NormalizeDouble(SlowMAPrev(),_Digits) <= NormalizeDouble(FastMAPrev(),_Digits)
      && NormalizeDouble(SlowMACurr(),_Digits) > NormalizeDouble(FastMACurr(),_Digits)
      && (MathAbs(SlowMACurr() - FastMACurr()) > DIFFERENCE)){
      sell = true;  
   }
   return sell;
}


// Kauforder setzen
void BuyOrder(){
   Print("Buy Order");
   
   double StopLoss = calcSL(BUY);
   double TakeProfit = calcTP(BUY);
   
   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);
   
   Print("BUY / Bid:" + last_tick.bid + "/Ask:" + last_tick.ask +"/StopLoss:" + StopLoss + "/TakeProfit:" + TakeProfit);
   
   openOrderID = OrderSend(NULL,OP_BUY,LOT,last_tick.ask,3,StopLoss,TakeProfit,NULL,magicNB,0,clrBlue);

   if(openOrderID < 0){
      Print("Fehler Buy: Order nicht ausgeführt, Code: #" +GetLastError());
   }else{
      Print("Buy Order wurde ausgeführt");
   }
}


// Verkaufsorder setzen
void SellOrder(){
   Print("Sell Order");

   double StopLoss = calcSL(SELL);
   double TakeProfit = calcTP(SELL);
   
   MqlTick last_tick;
   SymbolInfoTick(_Symbol,last_tick);

   Print("SELL / Bid:" + last_tick.bid + "/Ask:" + last_tick.ask +"/StopLoss:" + StopLoss + "/TakeProfit:" + TakeProfit);

   openOrderID = OrderSend(NULL,OP_SELL,LOT,last_tick.bid,3,StopLoss,TakeProfit,NULL,magicNB,0,clrRed);

   if(openOrderID < 0){
      Print("Fehler Sell: Order nicht ausgeführt, Code: #" +GetLastError());
   }else{
      Print("Sell Order wurde ausgeführt");
   }
}

bool CheckOpenBuyOrder(){
   for(int i=0; i < OrdersTotal(); i++){
      if(OrderGetTicket(i) > 0){
         if(OrderGetInteger(ORDER_MAGIC) == magicNB && OrderGetString(ORDER_SYMBOL) == Symbol()){
            if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_BUY){
               return true;
            }
         }
      }
   }
   return false;
}

bool CheckOpenSellOrder(){
   for(int i=0; i < OrdersTotal(); i++){
      if(OrderGetTicket(i) > 0){
         if(OrderGetInteger(ORDER_MAGIC) == magicNB && OrderGetString(ORDER_SYMBOL) == Symbol()){
            if(OrderGetInteger(ORDER_TYPE) == ORDER_TYPE_SELL){
               return true;
            }
         }
      }
   }
   return false;
}

void CloseBuyOrder(int ticket,double lots,double price){
   OrderClose(ticket,lots,price,0,clrRed);
}


void CloseSellOrder(int ticket,double lots,double price){
   OrderClose(ticket,lots,price,0,clrBlue);
}

// StopLoss berechnen
double calcSL(BuySell typ){
   switch(typ){
      // Buy
      case BUY:
         if(SL == 0){
            return SL;
         }else if(SL < minSL){
            Alert("StopLoss zu klein wird auf Minimum(" + minSL + ") gesetzt");
            return NormalizeDouble(Bid-minSL*Point,Digits);
         }else{
            return NormalizeDouble(Bid-SL*Point,Digits);
         }
         break;
     // Sell
     case SELL:
         if(SL == 0){
            return SL;
         }else if(SL < minSL){
            Alert("StopLoss zu klein wird auf Minimum(" + minSL + ") gesetzt");
            return NormalizeDouble(Ask+minSL*Point,Digits);
         }else{
            return NormalizeDouble(Ask+SL*Point,Digits);
         }
         break;
   }
   return 0;
}

// TakeProfit berechnen
double calcTP(BuySell typ){
   switch(typ){
      // Buy
      case BUY:
         if(TP == 0){
            return TP;
         }else if(TP < minSL){
            Alert("TakeProfit zu klein wird auf Minimum(" + minSL + ") gesetzt");
            return NormalizeDouble(Bid+minSL*Point,Digits);
         }else{
            return NormalizeDouble(Bid+TP*Point,Digits);
         }      
         break;
      // Sell
      case SELL:
         if(TP == 0){
            return TP;
         }else if(TP < minSL){
            Alert("TakeProfit zu klein wird auf Minimum(" + minSL + ") gesetzt");
            return NormalizeDouble(Ask-minSL*Point,Digits);
         }else{
            return NormalizeDouble(Ask-TP*Point,Digits);
         }      
   }
   return 0;
}

//+------------------------------------------------------------------+

