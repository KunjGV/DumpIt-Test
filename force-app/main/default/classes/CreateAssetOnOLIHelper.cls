public class CreateAssetOnOLIHelper {
    public static void createAsset(List<OpportunityLineItem> newOLI){
        Set<Id> opp = new Set<Id>();
        for(OpportunityLineItem oli : newOLI){
            opp.add(oli.OpportunityId);
        }
        Map<Id, Opportunity> oppAccounts = new Map<Id, Opportunity>([SELECT AccountId, Name FROM Opportunity WHERE Id IN :opp]);
        List<Asset> createAssets = new List<Asset>();
        for(OpportunityLineItem thisOLI : newOLI){
            if(oppAccounts.get(thisOLI.OpportunityId).AccountId != null){
                Asset newAsset = new Asset();
                newAsset.Name = oppAccounts.get(thisOLI.OpportunityId).Name + ' Asset';
                newAsset.AccountId = oppAccounts.get(thisOLI.OpportunityId).AccountId;
                newAsset.Product2Id = thisOLI.Product2Id;
                createAssets.add(newAsset);
            } else {
                thisOLI.addError('Record could not be created as the Account is not populated on the opportunity.');
            }
        }
        if(!createAssets.isEmpty()){
            insert createAssets;
        }
    }
}