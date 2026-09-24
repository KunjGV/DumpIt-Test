trigger LeadTrigger on Lead (before insert, after insert) {
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            LeadCloneHelper.createDuplicate(Trigger.New);
        }
    }
}