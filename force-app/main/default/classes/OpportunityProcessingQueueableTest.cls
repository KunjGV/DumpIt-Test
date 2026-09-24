@IsTest
private class OpportunityProcessingQueueableTest {

    @IsTest
    static void execute_amountBelow10k_categorySmall() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 9999;
        insert opps;

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(new Set<Id>{ opps[0].Id }));
        Test.stopTest();

        Opportunity result = [
            SELECT Opportunity_Category__c, Processed__c, Processing_Date__c
            FROM   Opportunity WHERE Id = :opps[0].Id
        ];
        Assert.areEqual('Small', result.Opportunity_Category__c);
        Assert.isTrue(result.Processed__c);
        Assert.isNotNull(result.Processing_Date__c);
    }

    @IsTest
    static void execute_amountExactly10k_categoryMedium() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 10000;
        insert opps;

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(new Set<Id>{ opps[0].Id }));
        Test.stopTest();

        Opportunity result = [SELECT Opportunity_Category__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.areEqual('Medium', result.Opportunity_Category__c);
    }

    @IsTest
    static void execute_amountBetween10kAnd50k_categoryMedium() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 30000;
        insert opps;

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(new Set<Id>{ opps[0].Id }));
        Test.stopTest();

        Opportunity result = [SELECT Opportunity_Category__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.areEqual('Medium', result.Opportunity_Category__c);
    }

    @IsTest
    static void execute_amountExactly50k_categoryMedium() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 50000;
        insert opps;

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(new Set<Id>{ opps[0].Id }));
        Test.stopTest();

        Opportunity result = [SELECT Opportunity_Category__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.areEqual('Medium', result.Opportunity_Category__c);
    }

    @IsTest
    static void execute_amountAbove50k_categoryLarge() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 50001;
        insert opps;

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(new Set<Id>{ opps[0].Id }));
        Test.stopTest();

        Opportunity result = [SELECT Opportunity_Category__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.areEqual('Large', result.Opportunity_Category__c);
    }

    @IsTest
    static void execute_successfulProcessing_createsSuccessLog() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(new Set<Id>{ opps[0].Id }));
        Test.stopTest();

        List<Processing_Log__c> logs = [
            SELECT Status__c, Message__c, Opportunity__c
            FROM   Processing_Log__c
            WHERE  Opportunity__c = :opps[0].Id
        ];
        Assert.areEqual(1, logs.size(), 'One log should be created');
        Assert.areEqual('Success', logs[0].Status__c);
        Assert.areEqual('Record Processed succesfully!', logs[0].Message__c);
    }

    @IsTest
    static void execute_bulk200Records_allProcessedWithLogs() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(200);
        for (Integer i = 0; i < opps.size(); i++) {
            opps[i].Amount = 1000 * (i + 1);
        }
        insert opps;

        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(oppIds));
        Test.stopTest();

        Integer processedCount = [
            SELECT COUNT() FROM Opportunity
            WHERE  Id IN :oppIds AND Processed__c = true
        ];
        Assert.areEqual(200, processedCount, 'All 200 should be processed');

        Integer logCount = [
            SELECT COUNT() FROM Processing_Log__c WHERE Opportunity__c IN :oppIds
        ];
        Assert.areEqual(200, logCount, '200 success logs should be created');
    }

    @IsTest
    static void execute_emptySet_noRecordsUpdated() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;

        Test.startTest();
        System.enqueueJob(new OpportunityProcessingQueueable(new Set<Id>()));
        Test.stopTest();

        Opportunity result = [SELECT Processed__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.isFalse(result.Processed__c, 'Empty Id set should not process any records');

        Integer logCount = [SELECT COUNT() FROM Processing_Log__c];
        Assert.areEqual(0, logCount, 'No logs should be created for an empty Id set');
    }
}