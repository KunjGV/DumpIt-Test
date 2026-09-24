public class ContactTriggerHelper {
    public static void isDuplicateRecord(List<Contact> newContacts){
        Set<String> uniqueKeys = new Set<String>();
        List<Contact> existingUniqueContacts = [SELECT Email, Phone FROM Contact WHERE (Email != null OR Phone != null)];
        for (Contact oldCon : existingUniqueContacts) {
            String concatenatedValue = null;
            if(oldCon.Email != null){
                concatenatedValue += oldCon.Email;
            }
            if(oldCon.Phone != null){
                concatenatedValue += oldCon.Phone;
            }
            uniqueKeys.add(concatenatedValue);
		}
        for (Contact con : newContacts) {
            String newConcatenatedValue = null;
            if(con.Email != null || con.Phone != null){
                newConcatenatedValue += (con.Email != null ? con.Email : '') + (con.Phone != null ? con.Phone : '');
            }
            if(uniqueKeys.contains(newConcatenatedValue)){
                con.addError('A contact record with duplicate Phone and Email already exists in the system');
            }
        }        
    }
    
    public static void checkBatchDuplicates(List<Contact> newContacts){
        Set<String> seenEmails = new Set<String>();
        for (Contact con: newContacts){
            if(String.isBlank(con.Email)) continue;
            String email = con.Email.toLowerCase().trim();
            if(seenEmails.contains(email)){
                con.addError('Another contact with same email already exists in the same batch');
            } else {
                seenEmails.add(email);
            }
        }
    }
    
    public static void isActive(List<Contact> oldRecord){
        for(Contact con: oldRecord){
            if(con.Active__c == true){
                con.Active__c.addError('The record cannot be deleted as the contact is still active.');
            }
        }
    }
}