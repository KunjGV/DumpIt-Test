public class UpdateOpportunityOnAccountTrigger {
    public static void updatedAccount(List<Account> updatedAccount){
        Set<Id> accIds = new Set<Id>();
        for(Account updatedAcc : updatedAccount){
            accIds.add(updatedAcc.Id);
        }
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        for(Opportunity opp : [SELECT Id, StageName, CloseDate FROM Opportunity WHERE AccountId IN :accIds AND StageName != 'Closed Won' AND CreatedDate < LAST_N_DAYS:30]){
            opp.StageName = 'Closed Lost';
            opp.CloseDate = System.Today();
            oppToUpdate.add(opp);
        }
        update oppToUpdate;
    }
}