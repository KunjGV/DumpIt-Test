public class CustomOrderQueueable implements Queueable {
    private Set<Id> orderIds;

    public CustomOrderQueueable(Set<Id> orderIds) {
        this.orderIds = orderIds;
    }

    public void execute(QueueableContext context) {
        //a savepoint is created to handle a situation in case an error occurs, an easy rollback can be done to this point
        System.Savepoint sp = Database.setSavepoint();
        
        try {
            Map<Id, Integer> pointsMapping = new Map<Id, Integer>();
        
            //Loyalty points allocation to the successfully delivered orders
            for (Order__c order : [SELECT Id, Account__c, Order_Amount__c FROM Order__c WHERE Id IN :orderIds AND Account__c != null]){
                Decimal amount = order.Order_Amount__c != null ? order.Order_Amount__c : 0;
                Integer pointsEarned = (Integer)Math.floor(amount / 100); //to fulfil the formula of 1 point per Rs. 100
                if (pointsEarned > 0) {
                    Integer existingPoints = pointsMapping.containsKey(order.Account__c) ? pointsMapping.get(order.Account__c) : 0;
                    pointsMapping.put(order.Account__c, existingPoints + pointsEarned); //since we want to increment the points and not recalculate them
                }
            }
            if(pointsMapping.isEmpty()){
                return;
            }
            
            //querying existing loyalty accounts for the target accounts, associated with the order
            Map<Id, Loyalty_Account__c> loyaltyAccountMap = new Map<Id, Loyalty_Account__c>();
            for (Loyalty_Account__c lAcc : [SELECT Id, Account__c, Points_Balance__c FROM Loyalty_Account__c WHERE Account__c IN :pointsMapping.keySet()]) {
                loyaltyAccountMap.put(lAcc.Account__c, lAcc);
            }

            List<Loyalty_Account__c> loyaltyAccountsToUpdate = new List<Loyalty_Account__c>();
            
            //processing updates and skipping if an account has not loyalty account
            for(Id accId : pointsMapping.keySet()){
                if(loyaltyAccountMap.containsKey(accId)){
                    Loyalty_Account__c lAcc = loyaltyAccountMap.get(accId);
                    Decimal currentBalance = lAcc.Points_Balance__c != null ? lAcc.Points_Balance__c : 0;
                    lAcc.Points_Balance__c = currentBalance + pointsMapping.get(accId);
                    loyaltyAccountsToUpdate.add(lAcc);
                } else {
                    System.debug(LoggingLevel.WARN, 'Skipping Processing: Account does not have a Loyalty Account setup. Account ID: ' + accId);
                }
            }
            if (!loyaltyAccountsToUpdate.isEmpty()) {
                Database.update(loyaltyAccountsToUpdate, true); 
            }
            
        } catch (Exception e){
            Database.rollback(sp);
            List<Order__c> ordersToRevert = new List<Order__c>();
            for (Id ordId : this.orderIds) {
                Order__c orders = new Order__c();
                orders.Id = ordId;
                orders.Points_Awarded__c = false;
                ordersToRevert.add(orders);
            }
            if (!ordersToRevert.isEmpty()) {
                Database.update(ordersToRevert, false);
            }
            System.debug(LoggingLevel.ERROR, 'Loyalty Points Job Failed. Critical Exception: ' + e.getMessage());
        }
    }
}