@isTest
public with sharing class AccountRateCardTest {
    
    @isTest
    static void testAccountInsertionSuccess() {
        
        //Positive Test Case: Rate Card found for the date range specified in the inserted acount 
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(1);
        insert cards;

        List<Account> accs = TestDataFactory.createAccount(5);

        Test.startTest();
        insert accs;
        Test.stopTest();

        List<Account> results = [SELECT Id, Rate__c, Rate_Card_Error__c FROM Account WHERE Id IN :accs];
        
        for (Account acc : results) {
            Assert.areEqual(150.00, acc.Rate__c);
            Assert.areEqual(null, acc.Rate_Card_Error__c);
        }

    }

    @isTest
    static void testAccountInsertionFailure() {
        
        //Negative Test Case: Rate Card NOT found for the date range specified in the inserted acount
        List<Account> accs = TestDataFactory.createAccount(5);

        Test.startTest();
        insert accs;
        Test.stopTest();

        List<Account> results = [SELECT Id, Rate__c, Rate_Card_Error__c FROM Account WHERE Id IN :accs];
        
        for (Account acc : results) {
            Assert.areEqual(null, acc.Rate__c);
            Assert.areEqual(RateCardConstants.noRateCardFoundError, acc.Rate_Card_Error__c);
        }

    }

    @isTest
    static void testAccountUpdationRateRecalculation() {
        
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(2);
        insert cards;

        List<Account> accs = TestDataFactory.createAccount(2);
        insert accs; 

        Test.startTest();

        for (Account acc : accs) {
            acc.Start_Date__c = Date.newInstance(2026, 2, 1);
            acc.End_Date__c = Date.newInstance(2026, 2, 10);
        }

        update accs;

        Test.stopTest();

        List<Account> results = [SELECT Id, Rate__c, Rate_Card_Error__c FROM Account WHERE Id IN :accs];
        
        for (Account acc : results) {
            Assert.areNotEqual(null, acc.Rate__c);
            Assert.areEqual(null, acc.Rate_Card_Error__c);
        }

    }

    @isTest
    static void testBatchExecutionSuccess() {
        
        //Positive Test Case: Rate Card found for the date range specified in the inserted acounts
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(1);
        insert cards;

        List<Account> batchAccounts = new List<Account>();
        
        for (Integer i = 0; i < 5; i++) {
            batchAccounts.add(new Account(
                Name = 'Successful Batch ' + i,
                Start_Date__c = Date.newInstance(2026, 1, 5),
                End_Date__c = Date.newInstance(2026, 1, 10)
            ));
        }
        
        insert batchAccounts;

        Test.startTest();
        Database.executeBatch(new AccountRateCardBatchable(), 20);
        Test.stopTest();

        List<Account> successResults = [SELECT Id, Rate__c, Rate_Card_Error__c FROM Account WHERE Name LIKE 'Successful Batch%'];
        
        for (Account acc : successResults) {
            Assert.areNotEqual(null, acc.Rate__c);
            Assert.areEqual(null, acc.Rate_Card_Error__c);
        }

    }

    @isTest
    static void testBatchExecutionFailure() {
        
        //Negative Test Case: Rate Card NOT found for the date range specified in the inserted acounts
        List<Account> batchAccounts = new List<Account>();
        
        for (Integer i = 0; i < 5; i++) {
            batchAccounts.add(new Account(
                Name = 'Failed Batch ' + i,
                Start_Date__c = Date.newInstance(2027, 1, 1),
                End_Date__c = Date.newInstance(2027, 1, 10)
            ));
        }
        
        insert batchAccounts;

        Test.startTest();
        Database.executeBatch(new AccountRateCardBatchable(), 20);
        Test.stopTest();

        List<Account> failResults = [SELECT Id, Rate__c, Rate_Card_Error__c FROM Account WHERE Name LIKE 'Failed Batch%'];
        
        for (Account acc : failResults) {
            Assert.areEqual(null, acc.Rate__c);
            Assert.areEqual(RateCardConstants.noRateCardFoundError, acc.Rate_Card_Error__c);
        }

    }

    @isTest
    static void testRateCardScheduler() {
        
        Test.startTest();
        AccountRateCardScheduler.scheduleJob();
        Test.stopTest();

        List<CronTrigger> scheduledJobs = [SELECT Id, CronJobDetail.Name FROM CronTrigger WHERE CronJobDetail.Name = :AccountRateCardScheduler.jobName];
        
        Assert.areEqual(1, scheduledJobs.size());

    }

    //RATE CARD TRIGGER TEST CASES

    @isTest
    static void testRateCardOverlapValidations() {
        
        // Negative Test Case: Throw Overlap Error
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(1);
        insert cards;

        Rate_Card__c duplicateCard = new Rate_Card__c(
            Start_Date__c = Date.newInstance(2026, 1, 10),
            End_Date__c = Date.newInstance(2026, 1, 20),
            Rate__c = 500
        );

        Test.startTest();
        
        try {
            insert duplicateCard;
            Assert.isTrue(false);
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains(RateCardConstants.rateCardOverlapError));
        }
        
        Test.stopTest();

    }

    @isTest
    static void testRateCardAfterInsertRecalculation() {
        
        // Positive Test Case: handleAfterInsert recalculates Rate__c for accounts whose rate card didn't exist earlier.
        List<Account> accs = TestDataFactory.createAccount(2);
        insert accs; 

        accs[0].Rate_Card_Error__c = RateCardConstants.noRateCardFoundError;
        update accs[0];

        Assert.areEqual(RateCardConstants.noRateCardFoundError, [SELECT Rate_Card_Error__c FROM Account WHERE Id = :accs[0].Id].Rate_Card_Error__c);

        Test.startTest();
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(1);
        insert cards;
        Test.stopTest();

        Account updatedAcc = [SELECT Rate__c, Rate_Card_Error__c FROM Account WHERE Id = :accs[0].Id];

        Assert.areNotEqual(null, updatedAcc.Rate__c);
        Assert.areEqual(null, updatedAcc.Rate_Card_Error__c);

    }

    @isTest
    static void testRateCardAfterUpdateRecalculation() {
        
        // Positive Test Case: handleAfterUpdate passed. It recalculates the Rate__c on Account Records if the Rate__c on the Rate Card is updated.
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(1);
        insert cards;

        List<Account> accs = TestDataFactory.createAccount(1);
        insert accs; 
        
        //Test.stopTest(); // Flush original async queueable runs cleanly before changing values
        
        Test.startTest();
        cards[0].Rate__c = 620.00;
        update cards;
        Test.stopTest();

        Account updatedAcc = [SELECT Rate__c FROM Account WHERE Id = :accs[0].Id];
        Assert.areEqual(300.00, updatedAcc.Rate__c);

    }

    @isTest
    static void testRateCardDeletion() {
        
        // Negative Test Case: Prevents deletion of a rate card that is currently being used by one or more accounts
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(1);
        insert cards;

        List<Account> accs = TestDataFactory.createAccount(1);
        insert accs; 

        Test.startTest();
        try {
            delete cards;
            Assert.isTrue(false);
        } catch (DmlException e) {
            Assert.isTrue(e.getMessage().contains(RateCardConstants.rateCardDeletionError));
        }
        Test.stopTest();

    }

    
    @isTest
    static void testRateCardAfterUndeletion() {
    
        List<Rate_Card__c> cards = TestDataFactory.createRateCards(1);
        insert cards;

        delete cards;

        //Creating an Account with overlapping dates as the deleted rate card
        List<Account> accs = TestDataFactory.createAccount(1);
        insert accs; 

        accs[0].Rate_Card_Error__c = RateCardConstants.noRateCardFoundError;
        update accs[0];

        Assert.areEqual(RateCardConstants.noRateCardFoundError, [SELECT Rate_Card_Error__c FROM Account WHERE Id = :accs[0].Id].Rate_Card_Error__c);

        Test.startTest();
        undelete cards;
        Test.stopTest();

        Account updatedAcc = [SELECT Rate__c, Rate_Card_Error__c FROM Account WHERE Id = :accs[0].Id];

        Assert.areNotEqual(null, updatedAcc.Rate__c);
        Assert.areEqual(null, updatedAcc.Rate_Card_Error__c);

    }

    @isTest
    static void testPartialRateCardCoverage() {
        
        // Partial Test Case: Rate Card covers only part of the Account's date range
        Rate_Card__c partialCard = new Rate_Card__c(
            Start_Date__c = Date.newInstance(2026, 3, 1),
            End_Date__c = Date.newInstance(2026, 3, 15),
            Rate__c = 310
        );
        insert partialCard;

        Account partialAccount = new Account(
            Name = 'Partial Coverage Account',
            Start_Date__c = Date.newInstance(2026, 3, 1),
            End_Date__c = Date.newInstance(2026, 3, 31)
        );

        Test.startTest();
        insert partialAccount;
        Test.stopTest();

        Account partialResult = [SELECT Rate__c, Rate_Card_Error__c FROM Account WHERE Id = :partialAccount.Id];
        
        Assert.areNotEqual(null, partialResult.Rate__c);
        Assert.areEqual(RateCardConstants.partialRateCardError, partialResult.Rate_Card_Error__c);

    }

}