public class ContactTriggerHandler {
    public Static Void beforeInsert(List<Contact> newContacts){
        ContactTriggerHelper.isDuplicateRecord(newContacts);
        ContactTriggerHelper.checkBatchDuplicates(newContacts);
    }
    public static void beforeUpdate(List<Contact> newContacts){
        ContactTriggerHelper.isDuplicateRecord(newContacts);
    }
    public static void afterInsert(List<Contact> newContact){
        ContactTriggerSendEmailHelper.sendEmail(newContact);
        ContactSequenceHelper.handleInsert(newContact);
    }
    public static void afterUpdate(List<Contact> newContact, Map<Id, Contact> oldConMap){
        ContactSequenceHelper.handleUpdate(newContact, oldConMap);
    }
    public static void afterDelete(List<Contact> oldContacts){
        ContactSequenceHelper.handleDelete(oldContacts);
    }
    public static void afterUndelete(List<Contact> newContact){
        ContactSequenceHelper.handleUndelete(newContact);
    }
}