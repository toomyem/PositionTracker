#property copyright   "Copyright 2017-2018, toomyem@toomyem.net"
#property version     "1.2"
#property strict
#property description "Automatically adjust SL according to closed bars"

//input bool IgnoreBarsAgainstPosition = true; // Ignore bars that are against open position

datetime lastTime;

double Spread() {
   return Ask - Bid;
}

int OnInit() {
   lastTime = Time[0];
   return(INIT_SUCCEEDED);
}

bool IsNewBar() {
   if(lastTime < Time[0]) {
      lastTime = Time[0];
      return true;
   }
   return false;
}

bool LastBarIsGreen() {
   return Open[1] < Close[1];
}

bool LastBarIsRed() {
   return Close[1] < Open[1];
}

bool StopLossIsHigherThenOpenPrice(double newStopLoss) {
   return newStopLoss > OrderOpenPrice();
}

bool StopLossIsLowerThenOpenPrice(double newStopLoss) {
   return newStopLoss < OrderOpenPrice();
}

void ModifyStopLoss(double newStopLoss) {
   PrintFormat("Set SL to: %0.2f", newStopLoss);
   if(!OrderModify(OrderTicket(), 0, newStopLoss, 0, 0)) {
      PrintFormat("Error: %s", GetLastError());
   }
}

bool IsLow(double &low) {
   if(Low[3] > Low[2] && Low[2] < Low[1]) {
      low = Low[2];
      PrintFormat("Found low: %0.2f", low);
      return true;
   }
   
   Print("No low");
   return false;
}

bool IsHigh(double &high) {
   if(High[3] < High[2] && High[2] > High[1]) {
      high = High[2];
      PrintFormat("Found high: %0.2f", high);
      return true;
   }
   
   Print("No high");
   return false;
}

void HandleBuyOrder() {
   double newStopLoss;
   
   if(IsLow(newStopLoss)) {
      PrintFormat("Spread: %0.2f", Spread());
      ModifyStopLoss(newStopLoss - Spread());
   }
}

void HandleSellOrder() {
   double newStopLoss;
   
   if(IsHigh(newStopLoss)) {
      PrintFormat("Spread: %0.2f", Spread());
      ModifyStopLoss(newStopLoss + Spread());
   }
}

void OnTick() {
   if(IsNewBar()) {
      
      int ordersNum = OrdersTotal();
      PrintFormat("New bar, %d orders", ordersNum);
      
      for(int i = 0; i < ordersNum; i++) {
      
         if(!OrderSelect(i, SELECT_BY_POS)) {
            PrintFormat("Cannot select order %d: %s", i, GetLastError());
            continue;
         }
         
         if(OrderSymbol() != ChartSymbol()) {
            PrintFormat("Ignore order %s", OrderSymbol());
            continue;
         }
         
         PrintFormat("Spread for %s: %0.2f", Symbol(), Spread());
         if(OrderType() == OP_BUY) {
            HandleBuyOrder();
         } else if(OrderType() == OP_SELL) {
            HandleSellOrder();
         } else {
            PrintFormat("Ignore order type: %d", OrderType());
         }
         
      }
   }
}
