trigger CustomOrderTrigger on Order__c (after update) {
    Set<Id> deliveredOrders = new Set<Id>();
    for(Order__c newOrders : Trigger.new){
        Order__c oldOrders = Trigger.oldMap.get(newOrders.Id);
        if(oldOrders.Status__c != 'Delivered' && newOrders.Status__c == 'Delivered' && newOrders.Points_Awarded__c == false){
            deliveredOrders.add(newOrders.Id);
        }
    }
    if(!deliveredOrders.isEmpty()){
        CustomOrderHelper.processLoyaltyPoints(deliveredOrders);
    }
}