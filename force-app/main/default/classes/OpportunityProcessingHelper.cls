public class OpportunityProcessingHelper {
    
    public static void handleInsert (List<Opportunity> newOpp){
        
        Set<Id> newOppIds = new Set<Id>();
        
        for(Opportunity opp : newOpp){
            if(opp.Amount != null){
                newOppIds.add(opp.Id);
            }
        }
        
        if(!newOppIds.isEmpty()){
            System.enqueueJob (new OpportunityProcessingQueueable(newOppIds));
        }
    }
    
    public static void handleUpdate(List<Opportunity> newOpp, Map<Id, Opportunity> oldMapOpp){
        
        Set<Id> newOppIds = new Set<Id>();
        
        for(Opportunity opp : newOpp){
            if(opp.Amount != null && opp.Amount != oldMapOpp.get(opp.Id).Amount){
                newOppIds.add(opp.Id);
            }
        }
        
        if(!newOppIds.isEmpty()){
            System.enqueueJob (new OpportunityProcessingQueueable(newOppIds));
        }
    }
}