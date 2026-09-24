trigger RateCardTrigger on Rate_Card__c (before insert, before update, before delete, after insert, after update, after undelete) {
    
    if (Trigger.isBefore){
        
        if (Trigger.isInsert){
            RateCardHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            RateCardHandler.beforeUpdate(Trigger.oldMap, Trigger.new);
        } else if (Trigger.isDelete){
            RateCardHandler.beforeDelete(Trigger.old);
        }
        
    } else if (Trigger.isAfter){

        if (Trigger.isInsert){
            RateCardHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            RateCardHandler.afterUpdate(Trigger.oldMap, Trigger.new);
        } else if (Trigger.isUndelete){
            RateCardHandler.afterInsert(Trigger.new);
        }

    }

}