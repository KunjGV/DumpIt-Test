public class OpportunityTriggerHandler {
    public static void afterInsert(List<Opportunity> newOpp){
        //OpportunityLineItemProductCreationHelper.createLineItemProduct(newopp);
        //OppCountOnAccountHelper.forCreateAndUndelete(newOpp);
        OpportunityProcessingHelper.handleInsert(newOpp);
    }
    public static void afterUpdate(List<Opportunity> newOpp, Map<Id, Opportunity> oldMapOpp){
        //OppCountOnAccountHelper.forUpdate(newOpp, oldMapOpp);
        OpportunityProcessingHelper.handleUpdate(newOpp, oldMapOpp);
    }
    public static void afterDelete(List<Opportunity> oldOpp){
        OppCountOnAccountHelper.forDelete(oldOpp);
    }
    public static void afterUndelete(List<Opportunity> newOpp){
        OppCountOnAccountHelper.forCreateAndUndelete(newOpp);
    }
}