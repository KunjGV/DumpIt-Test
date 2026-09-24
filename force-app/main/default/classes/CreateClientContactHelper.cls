public class CreateClientContactHelper {
    public static void clientContact(List<Account> newAcc){
        Set<Id> accId = new Set<Id>();
        for(Account acc : newAcc){
            accId.add(acc.Id);
        }
        Map<Id, Contact> newCon = new Map<Id, Contact>();
        for(Account acc: newAcc){
            Contact tempCon = new Contact();
            tempCon.AccountId = acc.Id;
            tempCon.LastName = acc.Name;
            tempCon.Joining_Date__c = System.today();
            newCon.put(acc.Id, tempCon);
            
        }
        if(!newCon.isEmpty()){
            insert newCon.Values();
        }
        List<Account> updateAccount = new List<Account>();
        For(Account acc: newAcc){
            Account tempAcc = new Account(Id = acc.Id, Client_Contact__c = newCon.get(acc.Id).Id);
            updateAccount.add(tempAcc);
        }
        if(!updateAccount.isEmpty()){
            update updateAccount;
        }
        
    }
}