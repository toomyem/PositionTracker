#property copyright   "Copyright 2017, toomyem@toomyem.net"
#property version     "1.0"
#property strict
#property description "Automatically adjust SL according to closed bars"

input bool IgnoreBarsAgainstPosition = false; // Ignore bars that are against open opsition

datetime lastTime = Time[0];

double Spread() {
   return Ask - Bid;
}

int OnInit() {
   Print("Ignore reverse bars is ", IgnoreBarsAgainstPosition);
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
   return IgnoreBarsAgainstPosition || (Open[1] < Close[1]);
}

bool LastBarIsRed() {
   return IgnoreBarsAgainstPosition || (Close[1] < Open[1]);
}

bool StopLossIsHigherThenOpenPrice(double newStopLoss) {
   return newStopLoss > OrderOpenPrice();
}

bool StopLossIsLowerThenOpenPrice(double newStopLoss) {
   return newStopLoss < OrderOpenPrice();
}

bool ShouldMoveStopLossUp(double newStopLoss) {
   return (OrderStopLoss() == 0 || newStopLoss > OrderStopLoss())
       && LastBarIsGreen()
       && StopLossIsHigherThenOpenPrice(newStopLoss);
}

bool ShouldMoveStopLossDown(double newStopLoss) {
   return (OrderStopLoss() == 0 || newStopLoss < OrderStopLoss())
       && LastBarIsRed()
       && StopLossIsLowerThenOpenPrice(newStopLoss);
}

void HandleBuyOrder() {
   double newStopLoss = Low[1] - Spread();
   if(ShouldMoveStopLossUp(newStopLoss)) {
      if(OrderModify(OrderTicket(), 0, newStopLoss, 0, 0)) {
         Print("Buy Order modified");
      }
   }
}

void HandleSellOrder() {
   double newStopLoss = High[1] + Spread();
   if(ShouldMoveStopLossDown(newStopLoss)) {
      if(OrderModify(OrderTicket(), 0, newStopLoss, 0, 0)) {
         Print("Sell Order modified");
      }
   }
}

void OnTick() {
   if(IsNewBar()) {
      Print("New bar");
      for(int i = 0; i < OrdersTotal(); i++) {
         if(OrderSelect(i, SELECT_BY_POS)) {
            if(OrderSymbol() == ChartSymbol()) {
               if(OrderType() == OP_BUY) {
                  HandleBuyOrder();
               } else if(OrderType() == OP_SELL) {
                  HandleSellOrder();
               }
            }
         }
      }
   }
}
