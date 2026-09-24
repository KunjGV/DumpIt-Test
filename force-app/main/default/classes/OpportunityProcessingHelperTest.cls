@IsTest
private class OpportunityProcessingHelperTest {

    @IsTest
    static void handleInsert_withAmount_processesRecord() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;

        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest(); // flushes Queueable synchronously

        Opportunity result = [
            SELECT Processed__c, Opportunity_Category__c, Processing_Date__c
            FROM   Opportunity
            WHERE  Id = :opps[0].Id
        ];
        Assert.isTrue(result.Processed__c, 'Processed__c should be true');
        Assert.areEqual('Small', result.Opportunity_Category__c, 'Category should be Small');
        Assert.isNotNull(result.Processing_Date__c, 'Processing_Date__c should be set');
    }

    @IsTest
    static void handleInsert_withAmount_createsSuccessLog() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;
    
        Id oppId = opps[0].Id; // capture Id before Test.startTest()
    
        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest();
    
        List<Processing_Log__c> logs = [
            SELECT Status__c, Message__c
            FROM   Processing_Log__c
            WHERE  Opportunity__c = :oppId
        ];
        Assert.areEqual(1, logs.size(), 'Exactly one log should be created');
        Assert.areEqual('Success', logs[0].Status__c);
        Assert.areEqual('Record Processed succesfully!', logs[0].Message__c);
    }
    @IsTest
    static void handleInsert_nullAmount_doesNotProcess() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        insert opps;

        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest();

        Opportunity result = [
            SELECT Processed__c FROM Opportunity WHERE Id = :opps[0].Id
        ];
        Assert.isFalse(result.Processed__c, 'Null Amount Opp should not be processed');

        Integer logCount = [SELECT COUNT() FROM Processing_Log__c WHERE Opportunity__c = :opps[0].Id];
        Assert.areEqual(0, logCount, 'No log should be created for null Amount');
    }

    @IsTest
    static void handleInsert_mixedAmounts_onlyNonNullProcessed() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(3);
        opps[0].Amount = 10000;
        // opps[1] → null
        opps[2].Amount = 25000;
        insert opps;

        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest();

        List<Opportunity> results = [
            SELECT Id, Processed__c FROM Opportunity WHERE Id IN :opps
        ];
        Map<Id, Opportunity> resultMap = new Map<Id, Opportunity>(results);

        Assert.isTrue(resultMap.get(opps[0].Id).Processed__c,  'Opp with Amount should be processed');
        Assert.isFalse(resultMap.get(opps[1].Id).Processed__c, 'Null Amount Opp should not be processed');
        Assert.isTrue(resultMap.get(opps[2].Id).Processed__c,  'Opp with Amount should be processed');
    }

    @IsTest
    static void handleInsert_bulk200_allProcessed() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(200);
        for (Integer i = 0; i < opps.size(); i++) {
            opps[i].Amount = 1000 * (i + 1);
        }
        insert opps;
    
        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();
    
        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest();
    
        Integer processedCount = [
            SELECT COUNT() FROM Opportunity
            WHERE  Id IN :oppIds AND Processed__c = true
        ];
        Assert.areEqual(200, processedCount, 'All 200 Opps should be processed');
    
        Integer logCount = [
            SELECT COUNT() FROM Processing_Log__c
            WHERE  Opportunity__c IN :oppIds
        ];
        Assert.areEqual(200, logCount, '200 log records should be created');
    }

    @IsTest
    static void handleInsert_amountBelow10k_categorySmall() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 9999;
        insert opps;

        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest();

        Opportunity result = [SELECT Opportunity_Category__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.areEqual('Small', result.Opportunity_Category__c);
    }

    @IsTest
    static void handleInsert_amountBetween10kAnd50k_categoryMedium() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 25000;
        insert opps;

        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest();

        Opportunity result = [SELECT Opportunity_Category__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.areEqual('Medium', result.Opportunity_Category__c);
    }

    @IsTest
    static void handleInsert_amountAbove50k_categoryLarge() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 75000;
        insert opps;

        Test.startTest();
        OpportunityProcessingHelper.handleInsert(opps);
        Test.stopTest();

        Opportunity result = [SELECT Opportunity_Category__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.areEqual('Large', result.Opportunity_Category__c);
    }

    @IsTest
    static void handleUpdate_amountChanged_reprocessesRecord() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;
    
        Opportunity oldOpp = opps[0].clone(true); // Amount = 5000
    
        opps[0].Amount = 60000;
        update opps;
    
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opps[0].Id => oldOpp };
    
        Test.startTest();
        OpportunityProcessingHelper.handleUpdate(opps, oldMap);
        Test.stopTest();
    
        Opportunity result = [
            SELECT Processed__c, Opportunity_Category__c, Processing_Date__c
            FROM   Opportunity WHERE Id = :opps[0].Id
        ];
        Assert.isTrue(result.Processed__c);
        Assert.areEqual('Large', result.Opportunity_Category__c);
        Assert.isNotNull(result.Processing_Date__c);
    }

    @IsTest
    static void handleUpdate_amountChanged_createsLog() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;
    
        Opportunity oldOpp = opps[0].clone(true);
    
        opps[0].Amount = 60000;
        update opps; // commit to DB before Queueable re-queries
    
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opps[0].Id => oldOpp };
    
        Test.startTest();
        OpportunityProcessingHelper.handleUpdate(opps, oldMap);
        Test.stopTest();
    
        List<Processing_Log__c> logs = [
            SELECT Status__c FROM Processing_Log__c WHERE Opportunity__c = :opps[0].Id
        ];
        Assert.areEqual(1, logs.size());
        Assert.areEqual('Success', logs[0].Status__c);
    }

    @IsTest
    static void handleUpdate_amountUnchanged_doesNotProcess() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;
    
        Opportunity oldOpp = opps[0].clone(true); 
    
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opps[0].Id => oldOpp };
    
        Test.startTest();
        OpportunityProcessingHelper.handleUpdate(opps, oldMap);
        Test.stopTest();
    
        Opportunity result = [SELECT Processed__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.isFalse(result.Processed__c, 'Unchanged Amount should not trigger processing');
    
        Integer logCount = [
            SELECT COUNT() FROM Processing_Log__c WHERE Opportunity__c = :opps[0].Id
        ];
        Assert.areEqual(0, logCount, 'No log when Amount is unchanged');    
    }

    @IsTest
    static void handleUpdate_newAmountNull_doesNotProcess() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(1);
        opps[0].Amount = 5000;
        insert opps;

        Opportunity oldOpp = opps[0].clone(true);
        opps[0].Amount = null;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>{ opps[0].Id => oldOpp };

        Test.startTest();
        OpportunityProcessingHelper.handleUpdate(opps, oldMap);
        Test.stopTest();

        Opportunity result = [SELECT Processed__c FROM Opportunity WHERE Id = :opps[0].Id];
        Assert.isFalse(result.Processed__c, 'Null new Amount should not trigger processing');
    }

    @IsTest
    static void handleUpdate_mixedChanges_onlyChangedAmountProcessed() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(2);
        opps[0].Amount = 5000;
        opps[1].Amount = 8000;
        insert opps;
    
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        for (Opportunity o : opps) oldMap.put(o.Id, o.clone(true));
    
        opps[0].Amount = 30000;
        update new List<Opportunity>{ opps[0] };
    
        Test.startTest();
        OpportunityProcessingHelper.handleUpdate(opps, oldMap);
        Test.stopTest();
    
        Map<Id, Opportunity> results = new Map<Id, Opportunity>([
            SELECT Id, Processed__c, Opportunity_Category__c
            FROM   Opportunity WHERE Id IN :opps
        ]);
    
        Assert.isTrue(results.get(opps[0].Id).Processed__c,  'Changed Opp should be processed');
        Assert.isFalse(results.get(opps[1].Id).Processed__c, 'Unchanged Opp should not be processed');
        Assert.areEqual('Medium', results.get(opps[0].Id).Opportunity_Category__c);
    }

    @IsTest
    static void handleUpdate_bulk200_allProcessed() {
        List<Opportunity> opps = TestDataFactory.createOpportunity(200);
        for (Opportunity o : opps) o.Amount = 1000;
        insert opps;
    
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        for (Opportunity o : opps) oldMap.put(o.Id, o.clone(true)); // old = 1000
    
        for (Opportunity o : opps) o.Amount = 75000;
        update opps;
    
        Set<Id> oppIds = new Map<Id, Opportunity>(opps).keySet();
    
        Test.startTest();
        OpportunityProcessingHelper.handleUpdate(opps, oldMap);
        Test.stopTest();
    
        Integer processedCount = [
            SELECT COUNT() FROM Opportunity
            WHERE  Id IN :oppIds
            AND    Processed__c = true
            AND    Opportunity_Category__c = 'Large'
        ];
        Assert.areEqual(200, processedCount, 'All 200 should be processed as Large');
    
        Integer logCount = [
            SELECT COUNT() FROM Processing_Log__c WHERE Opportunity__c IN :oppIds
        ];
        Assert.areEqual(200, logCount, '200 logs should be created');
    }
}