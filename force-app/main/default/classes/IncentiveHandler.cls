public class IncentiveHandler {
    public static void beforeInsert(List<Incentive__c> newIncs){
        IncentiveHelper.dupCheckBeforeInsert(newIncs);
    }
    public static void beforeUpdate(List<Incentive__c> oldIncs, Map<Id, Incentive__c> newIncs){
        IncentiveHelper.dupCheckBeforeUpdate(oldIncs, newIncs);
    }
    public static void beforeDelete(List<Incentive__c> oldIncs){
        IncentiveHelper.handleDelete(oldIncs);
    }
    public static void afterInsert(List<Incentive__c> newIncs){
        IncentiveHelper.handleInsert(newIncs);
    }
    public static void afterUpdate(List<Incentive__c> oldIncs, Map<Id, Incentive__c> newIncs){
        IncentiveHelper.handleUpdate(oldIncs, newIncs);
    }
}