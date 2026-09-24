trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert, after insert) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            OpportunityLineItemHandler.afterInsert(Trigger.new);
        }
    }
}