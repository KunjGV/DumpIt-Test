public class CustomOrderHelper {
    public static void processLoyaltyPoints(Set<Id> deliveredOrders){
        List<Order__c> ordersToUpdate = new List<Order__c>();
        for(Id orderIds : deliveredOrders){
            Order__c orders = new Order__c();
            orders.Id = orderIds;
            orders.Points_Awarded__c = true;
            ordersToUpdate.add(orders);
        }
        if(!ordersToUpdate.isEmpty()){
            update ordersToUpdate;
        }
        System.enqueueJob(new CustomOrderQueueable(deliveredOrders));
    }
}