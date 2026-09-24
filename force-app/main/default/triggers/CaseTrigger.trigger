trigger CaseTrigger on Case (before insert, after insert, after update) {
    /*
    if(Trigger.isInsert && Trigger.isBefore){
        for(Case caseRecord: Trigger.New){
            if(caseRecord.Origin == 'Phone'){
                caseRecord.Priority = 'High';
            } else {
                caseRecord.Priority = 'Low';
            }
        }
    } */
    if (Trigger.isAfter){
        if(Trigger.isInsert){
            //CaseHandler.futureCall(Trigger.new);
        } else if(Trigger.isUpdate){
            //CaseHandler.handleUpdate(Trigger.oldMap, Trigger.new);
        }
    }
}