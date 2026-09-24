trigger Project2TaskTrigger on Project_Task__c (before insert, after insert, before update, after update, after delete, after undelete) {
    if (Trigger.isBefore){
        if(Trigger.isInsert){
            Project2TaskHandler.beforeInsert(Trigger.new);
        } else if (Trigger.isUpdate){
            Project2TaskHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    } else if(Trigger.isAfter){
        if(Trigger.isInsert){
            Project2TaskHandler.afterInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            Project2TaskHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        } else if(Trigger.isDelete){
            Project2TaskHandler.afterDelete(Trigger.old);
        } else if(Trigger.isUndelete){
            Project2TaskHandler.afterUndelete(Trigger.new);
        }
    }
}