trigger OpportunityTrigger on Opportunity (after insert, after update, after delete, after undelete) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            OpportunityTriggerHandler.afterInsert(Trigger.new);
        }
        if(Trigger.isUpdate){
            OpportunityTriggerHandler.afterUpdate(Trigger.new, Trigger.OldMap);
        }
        if(Trigger.isDelete){
            OpportunityTriggerHandler.afterDelete(Trigger.old);
        }
        if(Trigger.isUndelete){
            OpportunityTriggerHandler.afterUndelete(Trigger.new);
        }
    } 
}