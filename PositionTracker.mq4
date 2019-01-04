#property copyright   "Copyright 2017-2018, toomyem@toomyem.net"
#property version     "1.1"
#property strict
#property description "Automatically adjust SL according to closed bars"

input bool IgnoreBarsAgainstPosition = false; // Ignore bars that are against open opsition
input bool MoveToBEOnPlus = true; // Move SL to BE as soon as bar is closed on plus

datetime lastTime;

double Spread() {
   return Ask - Bid;
}

int OnInit() {
   Print("Ignore reverse bars is ", IgnoreBarsAgainstPosition, " and Move to BE on plus is ", MoveToBEOnPlus);
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

bool ShouldMoveStopLossUp(double newStopLoss) {
   return (OrderStopLoss() == 0 || newStopLoss > OrderStopLoss())
       && (!IgnoreBarsAgainstPosition || LastBarIsGreen())
       && StopLossIsHigherThenOpenPrice(newStopLoss)
       && newStopLoss < Bid - Spread();
}

bool ShouldMoveStopLossDown(double newStopLoss) {
   return (OrderStopLoss() == 0 || newStopLoss < OrderStopLoss())
       && (!IgnoreBarsAgainstPosition || LastBarIsRed())
       && StopLossIsLowerThenOpenPrice(newStopLoss)
       && newStopLoss > Ask + Spread();
}

void ModifyStopLoss(double newStopLoss, string msg) {
   if(OrderModify(OrderTicket(), 0, newStopLoss, 0, 0)) {
      Print(msg);
   }
}

void HandleBuyOrder() {
   double newStopLoss = Low[1] - Spread();
   if(ShouldMoveStopLossUp(newStopLoss)) {
      ModifyStopLoss(newStopLoss, "Buy Order modified");
   } 

   newStopLoss = OrderOpenPrice() + Spread();
   if(ShouldMoveStopLossUp(newStopLoss)) {
      ModifyStopLoss(newStopLoss, "Buy Order modified to BE");
   }
}

void HandleSellOrder() {
   double newStopLoss = High[1] + Spread();
   if(ShouldMoveStopLossDown(newStopLoss)) {
      ModifyStopLoss(newStopLoss, "Sell Order modified");
   }

   newStopLoss = OrderOpenPrice() - Spread();
   if(ShouldMoveStopLossDown(newStopLoss)) {
      ModifyStopLoss(newStopLoss, "Sell Order modified to BE");
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
