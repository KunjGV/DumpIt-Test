public with sharing class ContactSequenceHelper {
    
    
    public static void handleInsert(List<Contact> newContacts) {
        Set<Id> accIds = new Set<Id>();
        for(Contact con : newContacts){
            if(con.AccountId != null){
                accIds.add(con.AccountId);
            }
        }
    }
    public static void handleUndelete(List<Contact> newContacts) {

    }
    public static void handleUpdate(List<Contact> newContacts, Map<Id, Contact> oldConMap) {

    }
    public static void handleDelete(List<Contact> oldContacts) {

    }
}