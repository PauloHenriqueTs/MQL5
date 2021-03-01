#include <Trade/Trade.mqh>

CTrade trade;
MqlRates rates[];
static datetime TimeStampLastCheck;

input datetime hour_init = D'03:15';
input double risk = 0.05;
input double pipValueInDollar = 0.13;
input double pipDigit = 1.0;
static int pipDigitsMult= 1/pipDigit;

static int IsOpenOrder = -1;
static int TwoReverse = 0;
int ATRDefinition;
int VwapDefinition;
static int Trend;

double ATR[];
double VWAP[];

enum PRICE_TYPE 
  {
   OPEN,
   CLOSE,
   HIGH,
   LOW,
   OPEN_CLOSE,
   HIGH_LOW,
   CLOSE_HIGH_LOW,
   OPEN_CLOSE_HIGH_LOW
};

int OnInit()
  {
   VwapDefinition = iCustom(_Symbol,_Period,"vwap","Volume Weighted Average Price (VWAP)",CLOSE_HIGH_LOW,true,false,false);
  ATRDefinition = iATR(_Symbol,_Period,14);
  ArraySetAsSeries(VWAP,true);
  ArraySetAsSeries(ATR,true);
    ArraySetAsSeries(rates,true);
    Trend = -1;
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
    CopyBuffer( VwapDefinition,0,0,3,VWAP);
    CopyBuffer(ATRDefinition,0,0,3,ATR);
    CopyRates(_Symbol,_Period,0,3,rates);
    
      if( IsNewCandle()){
         if(IsInitHour()){
           TwoReverse =0 ;
           IsOpenOrder=0;
            if(MarketOpenBullish()){
               DrawBullishLines();
               Trend=1;
            }
            if(MarketOpenBerish()){
               DrawBerishLines();
               Trend=0;
            }
         }
         
         else if(Trend == 1){
            double zonaNeutra;
            double CanalDeReferencia;
           
            ObjectGetDouble(_Symbol,"ZonaNeutraLow",OBJPROP_PRICE,0,zonaNeutra);
            ObjectGetDouble(_Symbol,"CanalDeReferencia",OBJPROP_PRICE,0,CanalDeReferencia);
              bool IsClosePriceLargerThenVwap=rates[1].close > VWAP[1];
              bool IsClosePriceLessThenVwap=rates[1].close < VWAP[1];
             bool IsClosePriceLessThenCanalDeReferencia =rates[1].close < CanalDeReferencia;
            bool IsClosePriceLessThenZonaNeutra =rates[1].close < zonaNeutra;
            bool IsClosePriceGreatherThenCanalDeReferencia =rates[1].close > CanalDeReferencia;
               if(IsClosePriceGreatherThenCanalDeReferencia && IsClosePriceLargerThenVwap){
                TwoReverse = 0;
                  OpenOrderBuy();
               }
             if(IsClosePriceLessThenZonaNeutra && IsClosePriceLessThenVwap){
               DrawBerishLines();
               Trend=0;
              
               IsOpenOrder=0;
        
               OpenOrderSell();
                TwoReverse = 1;
             }
          }
         else  if(Trend == 0){
            double zonaNeutra;
            double CanalDeReferencia;
            ObjectGetDouble(_Symbol,"ZonaNeutraLow",OBJPROP_PRICE,0,zonaNeutra);
            ObjectGetDouble(_Symbol,"CanalDeReferencia",OBJPROP_PRICE,0,CanalDeReferencia);
              bool IsClosePriceLargerThenVwap=rates[1].close > VWAP[1];
            bool IsClosePriceLessThenVwap=rates[1].close < VWAP[1];
            bool IsClosePriceGreatherThenZonaNeutra =rates[1].close > zonaNeutra;
            bool IsClosePriceLessThenCanalDeReferencia =rates[1].close < CanalDeReferencia;
               if(IsClosePriceLessThenCanalDeReferencia && IsClosePriceLessThenVwap){
                 TwoReverse = 0;
                 HistorySelect(0,TimeCurrent());
                  uint     total=HistoryDealsTotal();
                double profit=HistoryDealGetDouble(total,DEAL_PROFIT);
                if(profit <0){
                  IsOpenOrder=0;
                }
                  OpenOrderSell();
            
               }
                if(IsClosePriceGreatherThenZonaNeutra && IsClosePriceLargerThenVwap){
                  DrawBullishLines();
                  Trend=1;
                  IsOpenOrder=0;
            
                  OpenOrderBuy();
                  TwoReverse = 1;
                }
             }
         
         
            
           
         
         
      }
  
  
  
  }


bool IsInitHour(){
   MqlDateTime str1,str2;
   TimeToStruct(rates[1].time,str1);
   TimeToStruct(hour_init,str2);
   return str1.hour == str2.hour && str1.min== str2.min;
}


bool IsNewCandle( ){
      bool check =  rates[0].time != TimeStampLastCheck;
      TimeStampLastCheck=rates[0].time;
      return check;
}

bool MarketOpenBullish(){
   bool IsClosePriceLargerThenVwap=rates[1].close >VWAP[1];
   bool IsCloseCandleIsUpPrice = rates[1].close > rates[1].open;
   return  IsCloseCandleIsUpPrice;
}
bool MarketOpenBerish(){
   bool IsClosePriceLargerThenVwap=rates[1].close <VWAP[1];
   bool IsCloseCandleIsUpPrice = rates[1].close < rates[1].open;
   return  IsCloseCandleIsUpPrice;
}

void DrawBullishLines(){
   RemoveObjects();
               
   ObjectCreate(_Symbol,"CanalDeReferencia",OBJ_HLINE,0,TimeCurrent(),rates[1].close);
   ObjectSetInteger(_Symbol,"CanalDeReferencia",OBJPROP_COLOR,clrBlue);
   
   ObjectCreate(_Symbol,"CanalDeReferenciaLow",OBJ_HLINE,0,TimeCurrent(),rates[1].close-ATR[1]);
   ObjectSetInteger(_Symbol,"CanalDeReferenciaLow",OBJPROP_COLOR,clrBlue);  
   ObjectCreate(_Symbol,"ZonaNeutraLow",OBJ_HLINE,0,TimeCurrent(),rates[1].close-2*ATR[1]);
   
   ObjectCreate(_Symbol,"FirstProfitLine",OBJ_HLINE,0,TimeCurrent(),rates[1].close+2*ATR[1]);
   ObjectSetInteger(_Symbol,"FirstProfitLine",OBJPROP_COLOR,clrGreen);
   ObjectCreate(_Symbol,"SecondProfitLine",OBJ_HLINE,0,TimeCurrent(),rates[1].close+4*ATR[1]);
   ObjectSetInteger(_Symbol,"SecondProfitLine",OBJPROP_COLOR,clrGreen);
}
void DrawBerishLines(){
   RemoveObjects();
               
   ObjectCreate(_Symbol,"CanalDeReferencia",OBJ_HLINE,0,TimeCurrent(),rates[1].close);
   ObjectSetInteger(_Symbol,"CanalDeReferencia",OBJPROP_COLOR,clrBlue);
   ObjectCreate(_Symbol,"CanalDeReferenciaLow",OBJ_HLINE,0,TimeCurrent(),rates[1].close+ATR[1]);
   ObjectSetInteger(_Symbol,"CanalDeReferenciaLow",OBJPROP_COLOR,clrBlue);  
   ObjectCreate(_Symbol,"ZonaNeutraLow",OBJ_HLINE,0,TimeCurrent(),rates[1].close+2*ATR[1]);
   
   ObjectCreate(_Symbol,"FirstProfitLine",OBJ_HLINE,0,TimeCurrent(),rates[1].close-2*ATR[1]);
   ObjectSetInteger(_Symbol,"FirstProfitLine",OBJPROP_COLOR,clrGreen);
   ObjectCreate(_Symbol,"SecondProfitLine",OBJ_HLINE,0,TimeCurrent(),rates[1].close-4*ATR[1]);
   ObjectSetInteger(_Symbol,"SecondProfitLine",OBJPROP_COLOR,clrGreen);
}


void OpenOrderBuy(){

if(IsOpenOrder != 1  && TwoReverse ==0 ){
   CancelOrders();
    double stopLoss;
   double takeProfit;
   double price = NormalizeDouble(rates[0].high,_Digits);
   ObjectGetDouble(_Symbol,"ZonaNeutraLow",OBJPROP_PRICE,0,stopLoss);
   ObjectGetDouble(_Symbol,"SecondProfitLine",OBJPROP_PRICE,0,takeProfit);
   
  
   
   stopLoss = NormalizeDouble(stopLoss,_Digits);
   takeProfit = NormalizeDouble(takeProfit,_Digits);
   double test2 = takeProfit- price;
   double diffPriceAndTakeProfit = (takeProfit- price)*pipDigitsMult;
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double test = (balance*risk)/pipValueInDollar;
   double lotsize = ( ( test)  / (diffPriceAndTakeProfit/2) );
   lotsize = NormalizeDouble(lotsize,2);
   
   trade.Buy(lotsize,_Symbol,price,stopLoss,takeProfit,NULL);
   IsOpenOrder=1;
   }
  
   
}

void OpenOrderSell(){
   
  if(IsOpenOrder != 1 && TwoReverse ==0  ){
  CancelOrders();
   double stopLoss;
   double takeProfit; 
   double price = NormalizeDouble(rates[0].high,_Digits);
   ObjectGetDouble(_Symbol,"ZonaNeutraLow",OBJPROP_PRICE,0,stopLoss);
   ObjectGetDouble(_Symbol,"SecondProfitLine",OBJPROP_PRICE,0,takeProfit);
   
   
   stopLoss = NormalizeDouble(stopLoss,_Digits);
   takeProfit = NormalizeDouble(takeProfit,_Digits);
  
    double diffPriceAndTakeProfit =  (price-takeProfit)*pipDigitsMult;
    double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double lotsize = ( ( (balance*risk)/pipValueInDollar)  / (diffPriceAndTakeProfit/2) );
   lotsize = NormalizeDouble(lotsize,2);
   
   trade.Sell(lotsize,_Symbol,price,stopLoss,takeProfit,NULL);
   
   IsOpenOrder=1;
   }
}


void RemoveObjects(){
 int objects=ObjectsTotal(0);
   for (int i = 0; i < objects; i++)
   {
      string name = ObjectName(0, i);
      
            ObjectDelete(0, name);
      
   }
ObjectsDeleteAll(0, -1, -1);
  
}

void CancelOrders(){
   if(OrdersTotal() >0 ){
      for(int  i = OrdersTotal()-1;i>=0;i--){
            ulong  ticket = OrderGetTicket(i);
            trade.OrderDelete(ticket);
         }
         
   }
   if( PositionsTotal()>0){
      for(int  i = PositionsTotal()-1;i>=0;i--){
            int ticket = PositionGetTicket(i);
            trade.PositionClose(ticket);
         }
         
   }
   
}


     

