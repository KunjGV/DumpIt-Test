trigger AccountTrigger on Account (before insert, after insert, before update, after update) {
    
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            AccountTriggerHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            AccountTriggerHelper.phoneUpdateDependency(Trigger.New, Trigger.oldMap);
        }
    } else if (Trigger.isAfter){
        if(Trigger.isInsert){
            AccountTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            AccountTriggerHandler.afterUpdate(Trigger.New, Trigger.oldMap);
        }
    }
    
}