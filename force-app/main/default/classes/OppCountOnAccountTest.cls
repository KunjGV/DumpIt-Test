@isTest
public class OppCountOnAccountTest {
	@isTest
    public static void testLogic(){
        List<Account> accounts = TestDataFactory.createAccount(3);
        insert accounts;
        List<Opportunity> opps = TestDataFactory.createOpportunity(50);
        List<Opportunity> toDeleteOpps = new List<Opportunity>();
        for(Opportunity opp : opps){
            opp.accountId = accounts[0].id;
        }
        insert opps;
        Account acc = [SELECT Id, Number_Of_Opportunities__c FROM Account WHERE Id = :accounts[0].id];
        System.debug(acc.Number_Of_Opportunities__c);
        for(Integer i = 0; i < 50; i++){
            opps[i].accountId = i < 20 ? accounts[2].id : null;
            if(i > 10 && i < 21) toDeleteOpps.add(opps[i]);
        }
        test.startTest();
        update opps;
        test.stopTest();
        delete toDeleteOpps;
        undelete toDeleteOpps;
    }
}