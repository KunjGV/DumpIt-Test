public class CaseHandler {
    @future
    public static void casePriority(Set<Id> newRec){
        List<Case> updated = new List<Case>();
        for(Case cases : [SELECT Id, Priority FROM Case WHERE Id IN :newRec]){
            cases.Priority = 'Low';
            updated.add(cases);
        }
        if(!updated.isEmpty()){
            update updated;
        }
    }
    
    public static void futureCall(List<Case> newCase){
        Set<Id> newRec = new Set<Id>();
        List<Case> newStatus = [SELECT Id, Priority, Status FROM Case WHERE Id In :newCase AND Status = 'New'];
        for(Case cs : newStatus){
            newRec.add(cs.Id);
        }
        casePriority(newRec);
    }
   
    public static void handleInsert(List<Case> newCase){
        Set<Id> newRec = new Set<Id>();
        for(Case cs : newCase){
            if(cs.Status == 'New'){
                newRec.add(cs.Id);
            }
        }
        casePriority(newRec);
    }
    
    public static void handleUpdate(Map<Id, Case> oldCase, List<Case> newCase){
        Set<Id> newRec = new Set<Id>();
        for(Case cs : newCase){
            Case oldCs = oldCase.get(cs.Id);
            if(cs.Status != oldCs.Status){
                newRec.add(cs.Id);
            }
        }
        casePriority(newRec);
    }
}