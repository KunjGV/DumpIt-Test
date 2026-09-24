public class OpportunityProcessingQueueable implements Queueable {
    
    private Set<Id> oppIds = new Set<Id>();
    
    public OpportunityProcessingQueueable(Set<Id> oppIds){
        this.oppIds = oppIds;
    }
    
    public void execute(QueueableContext context){
        
        List<Opportunity> toUpdateOpps = new List<Opportunity>();
        List<Processing_Log__c> toInsertLogs = new List<Processing_Log__c>();
        
        for(Opportunity opp:[SELECT Id, Amount, Processed__c, Processing_Date__c, Opportunity_Category__c FROM Opportunity WHERE Id IN :oppIds]){
            opp.Opportunity_Category__c = opp.Amount <10000 ? 'Small' : opp.Amount > 50000 ? 'Large' : 'Medium';
            opp.Processed__c = true;
            opp.Processing_Date__c = System.now();
            toUpdateOpps.add(opp);
        }
        
        List<Database.SaveResult> resultList = new List<Database.SaveResult>();
        
        if(!toUpdateOpps.isEmpty()){
            resultList = Database.update(toUpdateOpps, false);
        }
        
        for(Database.SaveResult sr: resultList){
            Processing_Log__c tempLog = new Processing_Log__c();
            if(sr.isSuccess()){
                tempLog.Opportunity__c = sr.getId();
                tempLog.Status__c = 'Success';
                tempLog.Message__c = 'Record Processed succesfully!';
            }else{
                tempLog.Opportunity__c = sr.getId();
                tempLog.Status__c = 'Failed';
                tempLog.Message__c = 'Record failed to process.\n';
                for(Database.error err : sr.getErrors()){
                    tempLog.Message__c += err.getStatusCode() + ': ' + err.getMessage() + '\n';
                }
            }
            toInsertLogs.add(tempLog);
        }
        
        if(!toInsertLogs.isEmpty()){
            resultList = Database.insert(toInsertLogs, false);
        } 
    }
}