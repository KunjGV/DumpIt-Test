public class AccountTriggerHelper {
    public static void ratingUpdateDependency(List<Account> newAccount){
        for (Account acc: newAccount){
            if (acc.Industry != null && acc.Industry == 'Media'){
                acc.Rating = 'Hot';
            }
        }
    }
    public static void phoneUpdateDependency(List<Account> accRecord, Map<Id, Account> oldMap){
        for (Account acc: accRecord){
            if(oldMap != null && acc.Phone!= null && acc.Phone != oldMap.get(acc.Id).Phone){
                acc.Description = 'The Phone Number on this Account has been updated to ' + acc.Phone;
            } else if (oldMap != null && acc.Phone == null && acc.Phone != oldMap.get(acc.Id).Phone){
                acc.Description = null;
            }
        }
    }
    public static void createRelatedOpportunity(List<Account> newAcc){
        List<Opportunity> newOpp = new List<Opportunity>();
        for (Account acc: newAcc){
            Opportunity opp = new Opportunity();
            opp.Name = acc.Name;
            opp.StageName = 'Prospecting';
            opp.CloseDate = System.Today();
            opp.AccountId = acc.Id;
            newOpp.add(opp);
        }
        if(!newOpp.isEmpty()){
            insert newOpp;
        }
    }
    
    public static void billingAddressShippingAddress(List<Account> newAccount){
        for(Account acc : newAccount){
            acc.ShippingCountryCode = acc.BillingCountryCode;
            acc.ShippingStreet = acc.BillingStreet;
            acc.ShippingCity = acc.BillingCity;
            acc.ShippingPostalCode = acc.BillingPostalCode;
            acc.ShippingStateCode = acc.BillingStateCode;
            acc.ShippingLatitude = acc.BillingLatitude;
            acc.ShippingLongitude = acc.BillingLongitude;
        }
    }
    
}