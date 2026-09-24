public class AccountTriggerHandler {
    
    public static void beforeInsert(List<Account> newAccount){
        //AccountTriggerHelper.ratingUpdateDependency(newAccount);
        //AccountTriggerHelper.billingAddressShippingAddress(newAccount);
    }
    
    public static void afterInsert(List<Account> newAccount){
        //AccountTriggerHelper.createRelatedOpportunity(newAccount);
        CreateClientContactHelper.clientContact(newAccount);
        SendEmailToAdminHelper.sendEmail(newAccount);
        AccountRateCardHelper.handleInsert(newAccount);
    }
    
    public static void afterUpdate(List<Account> newAccount, Map<Id, Account> oldAccountMap){
        //UpdateOpportunityOnAccountTrigger.updatedAccount(newAccount);
        AccountRateCardHelper.handleUpdate(newAccount, oldAccountMap);
    }
}