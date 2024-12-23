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
void OnDeinit(const int reason) {

}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FastMACurr() {
   int ma = iMA(NULL,0,FASTMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1];
   CopyBuffer(ma,0,0,1,res);
   return res[0];
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double FastMAPrev() {
   int ma = iMA(NULL,0,FASTMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1];
   CopyBuffer(ma,0,1,1,res);
   return res[0];
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SlowMACurr() {
   int ma = iMA(NULL,0,SLOWMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1];
   CopyBuffer(ma,0,0,1,res);
   return res[0];
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SlowMAPrev() {
   int ma = iMA(NULL,0,SLOWMA,0,MODE_SMA,PRICE_CLOSE);
   double res[1];
   CopyBuffer(ma,0,1,1,res);
   return res[0];
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {

// Verkauf
   if(Sell()) {
      // Sell Signal

      // Wenn keine Sell Order vorhanden
      if(!CheckOpenSellOrder()) {
         // Wenn Buy Order vorhanden
         if(CheckOpenBuyOrder()) {
            // SChließe Buy Order
            CloseBuyOrder(PositionGetInteger(POSITION_TICKET),PositionGetDouble(POSITION_VOLUME));
            // Öffne Sell Order
            SellOrder();
            // Wenn keine Buy Order vorhanden
         } else {
            // Öffne Sell Order
            SellOrder();
         }
      }
   }
// Kauf
   if(Buy()) {
      // Buy Signal

      // Wenn keine Buy Order vorhanden
      if(!CheckOpenBuyOrder()) {
         // Wenn Sell Order vorhanden
         if(CheckOpenSellOrder()) {
            // Schließe Sell Order
            CloseSellOrder(PositionGetInteger(POSITION_TICKET),PositionGetDouble(POSITION_VOLUME));
            // Öffne Buy Order
            BuyOrder();
            // Wenn keine Sell Order vorhanden
         } else {
            // Öffne Buy Order
            BuyOrder();
         }
      }
   }
}

// Prüfen ob Kauf Signal
bool Buy() {
   bool buy = false;
   if(NormalizeDouble(SlowMAPrev(),_Digits) >= NormalizeDouble(FastMAPrev(),_Digits)
         && NormalizeDouble(SlowMACurr(),_Digits) < NormalizeDouble(FastMACurr(),_Digits)
         && (MathAbs(FastMACurr() - SlowMACurr()) > DIFFERENCE)) {
      buy = true;
   }
   return buy;
}

// Prüfen ob Verkauf Signal
bool Sell() {
   bool sell = false;
   if(NormalizeDouble(SlowMAPrev(),_Digits) <= NormalizeDouble(FastMAPrev(),_Digits)
         && NormalizeDouble(SlowMACurr(),_Digits) > NormalizeDouble(FastMACurr(),_Digits)
         && (MathAbs(SlowMACurr() - FastMACurr()) > DIFFERENCE)) {
      sell = true;
   }
   return sell;
}


// Kauforder setzen
void BuyOrder() {
   Print("Buy Order");

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   double StopLoss = calcSL(BUY);
   double TakeProfit = calcTP(BUY);

   request.action   =TRADE_ACTION_DEAL;                      // Typ der Transaktion
   request.symbol   =Symbol();                               // Symbol
   request.volume   =LOT;                                    // Lot
   request.type     =ORDER_TYPE_BUY;                        // Ordertyp
   request.price    =SymbolInfoDouble(Symbol(),SYMBOL_ASK);  // Eröffnungspreis
   request.deviation=3;                                      // zulässige Abweichung vom Kurs
   request.sl       =StopLoss;
   request.tp       =TakeProfit;
   request.magic    =magicNB;                                // MagicNumber der Order

   Print("Buy Order / Price:" +request.price+ ", SL:" +request.sl+", TP:"+request.tp);

// Anfrage senden
   if(!OrderSend(request,result)) {
      PrintFormat("Fehler Buy: Order nicht ausgeführt, Code: # %d",GetLastError());
   } else {
      Print("Buy Order wurde ausgeführt");
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
   }
}


// Verkaufsorder setzen
void SellOrder() {
   Print("Sell Order");

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   double StopLoss = calcSL(SELL);
   double TakeProfit = calcTP(SELL);

   request.action   =TRADE_ACTION_DEAL;                      // Typ der Transaktion
   request.symbol   =Symbol();                               // Symbol
   request.volume   =LOT;                                    // Lot
   request.type     =ORDER_TYPE_SELL;                        // Ordertyp
   request.price    =SymbolInfoDouble(Symbol(),SYMBOL_BID);  // Eröffnungspreis
   request.deviation=3;                                      // zulässige Abweichung vom Kurs
   request.sl       =StopLoss;
   request.tp       =TakeProfit;
   request.magic    =magicNB;                                // MagicNumber der Order

   Print("Sell Order / Price:" +request.price+ ", SL:" +request.sl+", TP:"+request.tp);

// Anfrage senden
   if(!OrderSend(request,result)) {
      PrintFormat("Fehler Sell: Order nicht ausgeführt, Code: # %d",GetLastError());
   } else {
      Print("Sell Order wurde ausgeführt");
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckOpenBuyOrder() {
   for(int i=0; i < PositionsTotal(); i++) {
      if(PositionGetTicket(i) > 0) {
         if(PositionGetInteger(POSITION_MAGIC) == magicNB && PositionGetString(POSITION_SYMBOL) == Symbol()) {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
               return true;
            }
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckOpenSellOrder() {
   for(int i=0; i < PositionsTotal(); i++) {
      if(PositionGetTicket(i) > 0) {
         if(PositionGetInteger(POSITION_MAGIC) == magicNB && PositionGetString(POSITION_SYMBOL) == Symbol()) {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
               return true;
            }
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseBuyOrder(int ticket,double lots) {

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = Symbol();
   request.volume = lots;
   request.deviation = 3;
   request.magic = magicNB;
   request.price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
   request.type =ORDER_TYPE_SELL;

// Anfrage senden
   if(!OrderSend(request,result)) {
      PrintFormat("Fehler Close Buy: Position nicht geschlossen, Code: # %d",GetLastError());
   } else {
      Print("Close Buy wurde ausgeführt");
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
   }
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseSellOrder(int ticket,double lots) {

   MqlTradeRequest request= {};
   MqlTradeResult  result= {};

   request.action = TRADE_ACTION_DEAL;
   request.position = ticket;
   request.symbol = Symbol();
   request.volume = lots;
   request.deviation = 3;
   request.magic = magicNB;
   request.price=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   request.type =ORDER_TYPE_BUY;

// Anfrage senden
   if(!OrderSend(request,result)) {
      PrintFormat("Fehler Close Sell: Position nicht geschlossen, Code: # %d",GetLastError());
   } else {
      Print("Close Sell wurde ausgeführt");
      PrintFormat("retcode=%u  deal=%I64u  order=%I64u",result.retcode,result.deal,result.order);
   }
}

// StopLoss berechnen
double calcSL(BuySell typ) {
   switch(typ) {
// Buy
   case BUY:
      if(SL == 0) {
         return SL;
      } else if(SL < minSL) {
         Alert("StopLoss zu klein wird auf Minimum(" + minSL + ") gesetzt");
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID)-minSL*Point(),Digits());
      } else {
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID)-SL*Point(),Digits());
      }
      break;
// Sell
   case SELL:
      if(SL == 0) {
         return SL;
      } else if(SL < minSL) {
         Alert("StopLoss zu klein wird auf Minimum(" + minSL + ") gesetzt");
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK)+minSL*Point(),Digits());
      } else {
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK)+SL*Point(),Digits());
      }
      break;
   }
   return 0;
}

// TakeProfit berechnen
double calcTP(BuySell typ) {
   switch(typ) {
// Buy
   case BUY:
      if(TP == 0) {
         return TP;
      } else if(TP < minSL) {
         Alert("TakeProfit zu klein wird auf Minimum(" + minSL + ") gesetzt");
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID)+minSL*Point(),Digits());
      } else {
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_BID)+TP*Point(),Digits());
      }
      break;
// Sell
   case SELL:
      if(TP == 0) {
         return TP;
      } else if(TP < minSL) {
         Alert("TakeProfit zu klein wird auf Minimum(" + minSL + ") gesetzt");
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK)-minSL*Point(),Digits());
      } else {
         return NormalizeDouble(SymbolInfoDouble(Symbol(),SYMBOL_ASK)-TP*Point(),Digits());
      }
   }
   return 0;
}

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
