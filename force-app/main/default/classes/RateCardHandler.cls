public with sharing class RateCardHandler {
    
    //Validates that newly inserted records do not overlap with each other, or with records already saved in the database
    public static void beforeInsert(List<Rate_Card__c> newRecords) {
        RateCardHelper.handleBeforeInsert(newRecords);
    }

    //Validates that updated records do not overlap with each other, or with records already saved in the database.
    public static void beforeUpdate(Map<Id, Rate_Card__c> oldRecords, List<Rate_Card__c> newRecords){
        RateCardHelper.handleBeforeUpdate(oldRecords, newRecords);
    }

    //It blocks the deletion of a Rate Card that is currently in use by one or more Account records
    public static void beforeDelete(List<Rate_Card__c> oldRecords) {
        RateCardHelper.handleBeforeDelete(oldRecords);
    }

    //When new Rate Cards are inserted, finds any Account currently showing "No Rate Card Found" error whose date range overlaps the new Rate Cards, and recalculates them.
    public static void afterInsert(List<Rate_Card__c> newRecords) {
        RateCardHelper.handleAfterInsert(newRecords);
    }
    
    //When a Rate Card's Rate value changes, this method finds every Account whose date range could overlap that Rate Card, and asks AccountRateCardHelper to recalculate their Rate so the new value is reflected immediately.
    public static void afterUpdate(Map<Id, Rate_Card__c> oldRecords, List<Rate_Card__c> newRecords){
        RateCardHelper.handleAfterUpdate(oldRecords, newRecords);
    }

}