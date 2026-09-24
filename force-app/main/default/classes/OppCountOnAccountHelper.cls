public class OppCountOnAccountHelper {
    private static Map<Id, Integer> countExistingOpp(Set<Id> AccountIds){
        AggregateResult[] countsOpp = [SELECT count(id) total, accountId FROM Opportunity WHERE accountId IN :AccountIds GROUP BY accountId];
        Map<Id, Integer> oppCount = new Map<Id, Integer>();
        for (AggregateResult ar : countsOpp){
            oppCount.put((id) ar.get('accountId'), (Integer) ar.get('total'));
        }
        return oppCount;
    }
    private static void updateAccField(Set<Id> accountIds){
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        Map<Id, Integer> oppCount = countExistingOpp(accountIds);
        for(Id accId : oppCount.keySet()){
            accountsToUpdate.put(accId, new Account(
            Id = accId,
            Number_Of_Opportunities__c = oppCount.get(accId)
            ));
        }
        if(!accountsToUpdate.isEmpty()){
            update accountsToUpdate.values();
        }
    }
    public static void forCreateAndUndelete(List<Opportunity> newOpp){
        Set<Id> accIds = new Set<Id>();
        for(Opportunity opp : newOpp){
            if(opp.AccountId != null){
                accIds.add(opp.AccountId);
            }
        }
        OppCountOnAccountHelper.updateAccField(accIds);
    }
    public static void forUpdate(List<Opportunity> newOpp, Map<Id, Opportunity> oldMapOpp){
        Set<Id> accIds = new Set<Id>();
        for(Opportunity opp : newOpp){
            Opportunity oppOld = oldMapOpp.get(opp.Id);
            if(opp.AccountId != oppOld.AccountId){
                if(opp.AccountId != null){
                    accIds.add(opp.AccountId);
                }
                if(oppOld.AccountId != null){
                    accIds.add(oppOld.AccountId);
                }
            }
        }
        OppCountOnAccountHelper.updateAccField(accIds);
    }
    public static void forDelete(List<Opportunity> oldOpp){
        Set<Id> accIds = new Set<Id>();
        for(Opportunity opp : oldOpp){
            if(opp.AccountId != null){
                accIds.add(opp.AccountId);
            }
        }
        OppCountOnAccountHelper.updateAccField(accIds);
    }
}