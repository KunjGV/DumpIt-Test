trigger ContactTrigger on Contact (after insert, after update, before insert, before update, before delete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            ContactTriggerHandler.beforeInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            for(Contact newCon : Trigger.New){
                Contact oldCon = Trigger.oldmap.get(newCon.Id);
                if(newCon.Email != oldCon.Email || newCon.Phone != oldCon.Phone){
                    ContactTriggerHandler.beforeUpdate(Trigger.new);
                }
            }
        } else if (Trigger.isDelete){
            ContactTriggerHelper.isActive(Trigger.Old);
        }   
    } else if (Trigger.isAfter){
        if(Trigger.isInsert){
            ContactTriggerHandler.afterInsert(Trigger.new);
        } else if(Trigger.isUpdate){
            ContactTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}