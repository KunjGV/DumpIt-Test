trigger IncentiveTrigger on Incentive__c (before insert, before update, before delete, after insert, after update) {
    if (Trigger.isAfter){
        if (Trigger.isInsert){
            IncentiveHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            IncentiveHandler.afterUpdate(Trigger.old, Trigger.newMap);
        }
    } else if (Trigger.isBefore){
        if(Trigger.isInsert){
            IncentiveHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            IncentiveHandler.beforeUpdate(Trigger.old, Trigger.newMap);
        } else if (Trigger.isDelete){
            IncentiveHandler.beforeDelete(Trigger.old);
        }
    }
}