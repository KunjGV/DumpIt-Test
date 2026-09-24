public class OpportunityLineItemHandler {
    public static void afterInsert(List<OpportunityLineItem> newOLI){
        CreateAssetOnOLIHelper.createAsset(newOLI);
        OLIEmailClientContactHelper.mailContact(newOLI);
        UpdateQuantityOnAccountHelper.updateQuantity(newOLI);
    }
}