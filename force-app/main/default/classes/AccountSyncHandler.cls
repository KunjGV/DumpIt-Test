public class AccountSyncHandler {

    @TestVisible private static Id testOverrideCurrentUserId = null;

    public static void handle(List<Account> newRecords, Map<Id, SObject> oldMap, Boolean isInsertContext) {
        Sync_Config__mdt cfg = Sync_Config__mdt.getInstance('OrgB_Sync');

        Id currentUserId = (Test.isRunningTest() && testOverrideCurrentUserId != null)
            ? testOverrideCurrentUserId
            : UserInfo.getUserId();

        if (currentUserId == cfg.Integration_User_Id__c) {
            return;
        }

        if (isInsertContext) {
            System.enqueueJob(new AccountSyncQueueable(newRecords, 'CREATE'));
            return;
        }

        List<Account> toUpdate = new List<Account>();
        for (Account acc : newRecords) {
            if (String.isBlank(acc.Org_B_Record_Id__c)) {
                continue;
            }
            Account oldAcc = (Account) oldMap.get(acc.Id);
            if (hasRelevantChange(acc, oldAcc)) {
                toUpdate.add(acc);
            }
        }

        if (!toUpdate.isEmpty()) {
            System.enqueueJob(new AccountSyncQueueable(toUpdate, 'UPDATE'));
        }
    }

    private static Boolean hasRelevantChange(Account newAcc, Account oldAcc) {
        return newAcc.Name != oldAcc.Name
            || newAcc.Phone != oldAcc.Phone
            || newAcc.BillingCity != oldAcc.BillingCity
            || newAcc.Industry != oldAcc.Industry
            || newAcc.Type != oldAcc.Type;
    }
}