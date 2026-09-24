@IsTest
public class OpportunityProcessingTest {
	
    //handles the processing for insertion of records
    @IsTest
    public static void testInsert(){
        List<Opportunity> opps = TestDataFactory.createOpportunity(80);
        for(Opportunity opp : opps){
            opp.Amount = 15000;
        }
        test.startTest();
        insert opps;
        test.stopTest();
        Opportunity opp = [Select Id, Amount, Processed__c, Processing_Date__c, Opportunity_Category__c FROM Opportunity WHERE Id = :opps[3].id];
        Assert.areEqual('Medium',opp.Opportunity_Category__c);
        Assert.areEqual(True, opp.Processed__c);
    }
    
    //handles the processing for updation of records
    @IsTest
    public static void testUpdate(){
        List<Opportunity> opps = TestDataFactory.createOpportunity(80);
        for(Opportunity opp : opps){
            opp.Amount = 15000;
        }
        insert opps;
        for(Opportunity opp:opps){
            opp.amount = 66000;
        }
        test.startTest();
        update opps;
        test.stopTest();
        Opportunity opp = [Select Id, Amount, Processed__c, Processing_Date__c, Opportunity_Category__c FROM Opportunity WHERE Id = :opps[3].id];
        Assert.areEqual('Large',opp.Opportunity_Category__c);
        Assert.areEqual(True, opp.Processed__c);
    }
    
    //handles the batch class
    @IsTest
    public static void testBatch(){
        List<Opportunity> opps = TestDataFactory.createOpportunity(80);
        for(Opportunity opp : opps){
            opp.Amount = 55000;
        }
        insert opps;
        test.startTest();
		database.executebatch(new OpportunityProcessingBatch());
        test.stopTest();
        Opportunity opp = [Select Id, Amount, Processed__c, Processing_Date__c, Opportunity_Category__c FROM Opportunity WHERE Id = :opps[2].id];
        Assert.areEqual('Large',opp.Opportunity_Category__c);
        Assert.areEqual(True, opp.Processed__c);
    }
}