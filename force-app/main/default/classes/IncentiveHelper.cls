public class IncentiveHelper {
    static Set<Id> processedParent = new Set<Id>();
    static List<String> months = new List<String>{'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December', 'January', 'February', 'March'};
        private static Map<Id,Incentive__c> queryChildIncentives(Set<Id> ParentIncs){            
            Map<Id,Incentive__c> queryIncs = new Map<Id,Incentive__c>([Select id, (select month__c from Incentives__r) from incentive__c Where Id in :ParentIncs]);
            return queryIncs;
        }
    
    private static void checkDuplicacy(List<Incentive__c> duplicates){
            Set<Id> ParentIncs = new Set<id>();
            for(Incentive__c inc:duplicates){
                ParentIncs.add(inc.parent_incentive__c);
            }
            Map<Id,Incentive__c> queryIncs = queryChildIncentives(ParentIncs);
            for(Incentive__c inc:duplicates){
                Incentive__c temp = queryIncs.get(inc.parent_incentive__c);
                if(temp.Incentives__r.size() != 0){
                    for(Incentive__c i:temp.Incentives__r){
                        if(inc.month__c == i.month__c){
                            inc.addError('Operation not allowed as duplicate month exists');
                        }
                    }
                }
            }
        }
    
    public static void dupCheckBeforeInsert(List<Incentive__c> newIncs){
        List<Incentive__c> duplicateIncs = new List<Incentive__c>();
        for (Incentive__c inc : newIncs){
            if(inc.month__c != null && inc.parent_incentive__c != null){
                duplicateIncs.add(inc);
            } else if (inc.month__c == null && inc.parent_incentive__c == null){
                /*if(inc.Amount__c == null){
                    inc.addError('Amount for a parent incentive must not be null.');
                }*/
            } else {
                inc.addError('Operation Restricted!');
            }
        }
        if(!duplicateIncs.IsEmpty()) checkDuplicacy(duplicateIncs);
    }
    
    public static void handleInsert(List<Incentive__c> newIncs){
            List<Incentive__c> childsToInsert = new List<Incentive__c>();
            
            for(Incentive__c inc:newIncs){
                if(inc.month__c == null && inc.parent_incentive__c == null){
                    Decimal childAmount = inc.amount__c != null && inc.amount__c > 0 ? inc.amount__c / 12 : 0;
                    for(String mon:months){
                        Incentive__c temp = new Incentive__c(month__c = mon, parent_incentive__c = inc.id, amount__c = childAmount, name = inc.Name + ' ' + mon);
                        childsToInsert.add(temp);
                    }
                }
            }
            if(!childsToInsert.isEmpty()) Database.Insert(childsToInsert, false);
        }
    
    public static void dupCheckBeforeUpdate(List<Incentive__c> oldIncs, Map<Id, Incentive__c> newIncs){
        List<Incentive__c> dupChildcheck = new List<Incentive__c>();
        for (Incentive__c inc : oldIncs){
            if(inc.month__c == null && inc.parent_incentive__c == null){
                if(newIncs.get(inc.id).month__c != null) inc.addError('Operation Restricted!');
                if(newIncs.get(inc.id).Parent_Incentive__c != null) inc.addError('Cannot add a Parent Incentive to an already parent incentive.');
                
            } else if (inc.month__c != null && inc.parent_incentive__c != null){
                if(newIncs.get(inc.id).Amount__c != inc.Amount__c && !processedParent.contains(inc.Parent_Incentive__c)) inc.addError('Operation Restricted!');
                if(newIncs.get(inc.id).Month__c != inc.Month__c) dupChildcheck.add(newIncs.get(inc.id));
                if(newIncs.get(inc.id).Parent_Incentive__c != inc.Parent_Incentive__c) dupChildcheck.add(newIncs.get(inc.id));
            } else{
                inc.addError('Operation Restricted!');
            }
        }
        if(!dupChildcheck.IsEmpty()) checkDuplicacy(dupChildcheck);
    }
    
    public static void handleUpdate(List<Incentive__c> oldIncs, Map<Id, Incentive__c> newIncs){
        Set<Id> parentIds = new Set<Id>();
        for (Incentive__c inc : oldIncs){
            if(inc.Month__c == null && inc.Parent_Incentive__c == null){
                parentIds.add(inc.Id);
            }
        }
        Map<Id,Incentive__c> queryIncs = queryChildIncentives(parentIds);
        List<Incentive__c> childsToUpdate = new List<Incentive__c>();
        for(Incentive__c inc:oldIncs){
            if(inc.month__c == null && inc.parent_incentive__c == null){
                if(newIncs.get(inc.id).month__c != null) inc.addError('Operation Restricted!');
                if(newIncs.get(inc.id).amount__c != inc.amount__c){
                    processedParent.add(inc.Id);
                    Decimal childAmount = newIncs.get(inc.id).amount__c != null && newIncs.get(inc.id).amount__c > 0 ? newIncs.get(inc.id).amount__c / 12 : 0;
                    for(Incentive__c childInc:queryIncs.get(inc.id).Incentives__r){
                        childInc.amount__c = childAmount;
                        childsToUpdate.add(childInc);
                    }
                }
            }
        }
        if(!childsToUpdate.isEmpty()) Database.Update(childsToUpdate, false);
    }
    
    public static void handleDelete(List<Incentive__c> oldIncs){
        Set<Id> parentIds = new Set<Id>();
        for (Incentive__c inc : oldIncs){
            if(inc.Month__c == null && inc.Parent_Incentive__c == null){
                parentIds.add(inc.Id);
            }
        }
        if(parentIds.isEmpty()) return;
        Map<Id,Incentive__c> queryIncs = queryChildIncentives(parentIds);
        List<Incentive__c> childsToDelete = new List<Incentive__c>();
        for (Incentive__c inc : oldIncs){
            childsToDelete.addAll(queryIncs.get(inc.Id).Incentives__r);
        }
        if(!childsToDelete.isEmpty()) delete childsToDelete;
    }
    
}