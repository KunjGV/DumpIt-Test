public class OpportunityLineItemProductCreationHelper {
    public static void createLineItemProduct(List<Opportunity> newOpp){
        List<OpportunityLineItem> LineItemList = new List<OpportunityLineItem>(); 
        PricebookEntry pbe = [SELECT Id, Product2Id, Product2.Name, UnitPrice FROM PricebookEntry WHERE Pricebook2.isStandard = true LIMIT 1];
        for(Opportunity opp: newOpp){
            OpportunityLineItem lineItem = new OpportunityLineItem(OpportunityId = Opp.Id, Product2Id = pbe.Product2Id, PricebookEntryId = pbe.Id, Quantity = 1, TotalPrice = 1 * pbe.UnitPrice);
            LineItemList.add(lineItem);
        }
        insert LineItemList;
    }
}