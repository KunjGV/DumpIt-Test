@isTest
private class AccountSyncTest {

    // Configurable mock — instantiate per test and set statusCode/responseBody
    private class MockResponse implements HttpCalloutMock {
        public Integer statusCode = 201;
        public String responseBody = '{"id":"001000000000001AAA","success":true,"errors":[]}';

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setBody(responseBody);
            return res;
        }
    }

    // INSERT: successful create, write-back happens
    @isTest
    static void testInsertCreatesAndWritesBackId() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());

        Test.startTest();
        insert new Account(Name = 'Test Sync Co');
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c], 'No failures should be logged on a successful create.');

        Account synced = [SELECT Org_B_Record_Id__c FROM Account WHERE Name = 'Test Sync Co'];
        Assert.areEqual('001000000000001AAA', synced.Org_B_Record_Id__c, 'The Id returned by the mocked POST should be written back onto the source record.');
    }

    // INSERT: failed create, failure logged, no write-back
    @isTest
    static void testInsertFailureIsLogged() {
        MockResponse mock = new MockResponse();
        mock.statusCode = 500;
        mock.responseBody = '{"error":"Server error"}';
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        insert new Account(Name = 'Fail On Create Co');
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Status_Code__c, Direction__c FROM Integration_Log__c];
        Assert.areEqual(1, logs.size(), 'A failed create should log exactly one row.');
        Assert.areEqual(500, logs[0].Status_Code__c, 'Logged status code should match the mocked response.');
        Assert.areEqual('OrgA_to_OrgB_CREATE', logs[0].Direction__c, 'Direction should reflect the CREATE operation.');

        Account acc = [SELECT Org_B_Record_Id__c FROM Account WHERE Name = 'Fail On Create Co'];
        Assert.isNull(acc.Org_B_Record_Id__c, 'A failed create must not populate the external ID field.');
    }

    // UPDATE: record not yet synced — must be skipped, not auto-created
    @isTest
    static void testUpdateSkippedWhenNotYetSynced() {
        MockResponse failMock = new MockResponse();
        failMock.statusCode = 500;
        Test.setMock(HttpCalloutMock.class, failMock);
        Account acc = new Account(Name = 'Unsynced Co');
        insert acc;

        Test.startTest();
        acc.Phone = '555-1234';
        update acc;
        Test.stopTest();

        List<Integration_Log__c> updateLogs = [
            SELECT Id FROM Integration_Log__c WHERE Direction__c = 'OrgA_to_OrgB_UPDATE'
        ];
        Assert.areEqual(0, updateLogs.size(), 'An update on an unsynced record must not trigger any outbound callout.');
    }

    private static Account createSyncedAccount(String name) {
        Account acc = new Account(Name = name);
        insert acc; 
        acc.Org_B_Record_Id__c = '001000000000099ZZZ';
        update acc;
        return acc;
    }

    // UPDATE: already synced, successful PATCH
    @isTest
    static void testUpdateSyncsWhenAlreadySynced() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        Account acc = createSyncedAccount('Synced Co');

        Test.startTest();
        acc.Phone = '555-5678';
        update acc; 
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c], 'A successful PATCH on an already-synced record should log no failures.');
    }

    // UPDATE: already synced, failed PATCH
    @isTest
    static void testUpdateFailureIsLogged() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        Account acc = createSyncedAccount('Update Fail Co');

        MockResponse failMock = new MockResponse();
        failMock.statusCode = 400;
        failMock.responseBody = '{"error":"Bad request"}';
        Test.setMock(HttpCalloutMock.class, failMock);

        Test.startTest();
        acc.Phone = '999-0000';
        update acc;
        Test.stopTest();

        List<Integration_Log__c> logs = [SELECT Status_Code__c, Direction__c FROM Integration_Log__c WHERE Direction__c = 'OrgA_to_OrgB_UPDATE'];
        Assert.areEqual(1, logs.size(), 'A failed update should log exactly one row.');
        Assert.areEqual(400, logs[0].Status_Code__c, 'Logged status code should match the mocked response.');
    }

    // UPDATE: no relevant field changed — must not sync at all
    @isTest
    static void testUpdateWithNoRelevantChangeIsSkipped() {
        Test.setMock(HttpCalloutMock.class, new MockResponse());
        Account acc = createSyncedAccount('No Change Co');

        Test.startTest();
        acc.Description = 'Not a tracked field';
        update acc;
        Test.stopTest();

        List<Integration_Log__c> updateLogs = [SELECT Id FROM Integration_Log__c WHERE Direction__c = 'OrgA_to_OrgB_UPDATE'];
        Assert.areEqual(0, updateLogs.size(), 'A change to an untracked field must not trigger an outbound sync.');
    }

    // Loop prevention
    @isTest
    static void testLoopPreventionSkipsIntegrationUserChanges() {
        Sync_Config__mdt cfg = Sync_Config__mdt.getInstance('OrgB_Sync');
        Assert.isNotNull(cfg.Integration_User_Id__c, 'Sync_Config__mdt.OrgB_Sync.Integration_User_Id__c must be populated for this test to be meaningful.');

        Test.setMock(HttpCalloutMock.class, new MockResponse());
        AccountSyncHandler.testOverrideCurrentUserId = cfg.Integration_User_Id__c;

        Test.startTest();
        insert new Account(Name = 'Loop Prevention Co');
        Test.stopTest();

        AccountSyncHandler.testOverrideCurrentUserId = null; 

        Account acc = [SELECT Org_B_Record_Id__c FROM Account WHERE Name = 'Loop Prevention Co'];
        Assert.isNull(acc.Org_B_Record_Id__c, 'A record saved by the integration user must not be synced back out.');
        Assert.areEqual(0, [SELECT COUNT() FROM Integration_Log__c], 'No callout should have been attempted for an integration-user-originated save.');
    }
}