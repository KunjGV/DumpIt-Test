public class LeadCloneHelper {
    public static void createDuplicate(List<Lead> newLead){
        List<Lead> cloneLead = new List<Lead>();
        for(Lead newRecord : newLead){
            if(!newRecord.isClone()){
                Lead tempLead = newRecord.clone();
                cloneLead.add(tempLead);
            } 
        }
        if(!cloneLead.isEmpty()){
            insert cloneLead;
        }
    }
}