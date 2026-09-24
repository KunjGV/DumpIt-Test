public with sharing class Project2TaskHelper {
    
    public static Map<Id, Project2__c> QueryTasks(Set<Id> parentIds){
        return new Map<Id, Project2__c>([Select id, Name, (select Id, Status__c, Project_Name__c from Project_Tasks__r) from Project2__c Where Id in :ParentIds]);
    }
    
    public static Integer getCompletedCount(List<Project_Task__c> totalTasks){
        Integer count = 0;
        for(Project_Task__c task : totalTasks){
            if(task.Status__c == 'Completed'){
                count++;
            }
        }
        return count;
    }
    
    @future
    private static void updateUser(Set<Id> userIds){
        Map<Id, User> queryUsers = new Map<Id, User>([SELECT Id, Busy__c FROM User WHERE Id IN :userIds]);
        List<AggregateResult> queryTasks = new List<AggregateResult>([SELECT COUNT(Id) taskCount, Assigned_To__c FROM Project_Task__c WHERE Assigned_To__c IN : userIds GROUP BY Assigned_To__c]);
        for(AggregateResult tsk : queryTasks){
            Integer count = (Integer) tsk.get('taskCount');
            Id userId = (Id) tsk.get('Assigned_To__c');
            if(count >= 1){
                queryUsers.get(userId).Busy__c = true;
            } else{
                userIds.remove(userId);
            }
        }
        for(Id userId: userIds){
           // queryUsers.get(userId).Busy__c = false;
        }
        system.debug(queryUsers);
        update queryUsers.values();
    }
    
      
    
    public static void handleBeforeInsert(List<Project_Task__c> newTasks){
        Set<Id> userIds = new Set<Id>();
        for(Project_Task__c tsk : newTasks){
            if(tsk.Status__c == 'Completed') tsk.addError('New Task cannot be marked as "Completed" on Insertion');
            tsk.Assigned_To__c = UserInfo.getUserId();
            userIds.add(tsk.Assigned_To__c);
        }
        updateUser(userIds);
    }
    
    public static void handleInsert(List<Project_Task__c> newTasks){
        //Set<Id> userIds = new Set<Id>();
        Set<Id> parentIds = new Set<Id>();
        //List<Project_Task__c> updateAssignedTo = new List<Project_Task__c>();
        for(Project_Task__c newRec : newTasks){
            parentIds.add(newRec.Project_Name__c);
            //userIds.add(newRec.CreatedById);
            //updateAssignedTo.add(new Project_Task__c(Id = newRec.Id, Assigned_To__c = newRec.CreatedById));
        }
        //update updateAssignedTo;
        //updateUser(userIds);
        Map<Id,Project2__c> queryTasks = QueryTasks(parentIds);
        Map<Id, Project2__c> updateProjectMap = new Map<Id, Project2__c>();
        for(Id projId : parentIds){
            Project2__c temp = new Project2__c(Id = projId);
            temp.Total_Tasks__c = queryTasks.get(projId).Project_tasks__r.size();
            temp.Name = queryTasks.get(projId).Name.endsWith(' - Completed') ? queryTasks.get(projId).Name.removeEnd(' - Completed') : queryTasks.get(projId).Name;
            updateProjectMap.put(projId, temp);
        }
        if(!updateProjectMap.isEmpty()){
            database.update(updateProjectMap.values(), false);
        }
    }
    
    public static void handleBeforeUpdate(List<Project_Task__c> newTasks, Map<Id, Project_Task__c> oldTaskMap){
        for(Project_Task__c tsk : newTasks){
            if(tsk.Assigned_To__c == null) tsk.addError('A user should be assigned to the task.');
        }
    }
    
    public static void handleUpdate(List<Project_Task__c> newTasks, Map<Id, Project_Task__c> oldTaskMap){
        Set<Id> parentIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        for(Project_Task__c newRec : newTasks){
            parentIds.add(newRec.Project_Name__c);
            if(newRec.Assigned_To__c != oldTaskMap.get(newRec.Id).Assigned_To__c){
                userIds.add(oldTaskMap.get(newRec.Id).Assigned_To__c);
                userIds.add(newRec.Assigned_To__c);
            } 
        }
        updateUser(userIds);
        Map<Id,Project2__c> queryTasks = QueryTasks(parentIds);
        Map<Id, Project2__c> updateProjectMap = new Map<Id, Project2__c>();
        for(Project_Task__c newRec : newTasks){
            Project_Task__c oldTaskRec = oldTaskMap.get(newRec.Id);
            if(oldTaskRec.Status__c != newRec.Status__c){
                Project2__c proj = queryTasks.get(newRec.Project_Name__c);
                Integer totalCount = proj.Project_Tasks__r.size();
                Integer completedCount = getCompletedCount(proj.Project_Tasks__r);
                Project2__c temp = new Project2__c(Id = newRec.Project_Name__c);
                temp.Completed_Tasks__c = completedCount;
                temp.Name = proj.Name;
                if(newRec.Status__c == 'Completed'){
                    if(totalCount == completedCount) temp.Name = proj.Name + ' - Completed';
                } else if(newRec.Status__c != 'Completed'){
                    if(proj.Name.endsWith(' - Completed') || (totalCount == completedCount && totalCount == 0)) temp.Name = proj.Name.removeEnd(' - Completed');
                }
                updateProjectMap.put(newRec.Project_Name__c, temp);
            }
        }
        if(!updateProjectMap.isEmpty()){
            database.update(updateProjectMap.values(), false);
        }
    }
    
    public static void handleDelete(List<Project_Task__c> oldTasks){
        Set<Id> parentIds = new Set<Id>();
        Set<Id> userIds = new Set<Id>();
        for(Project_Task__c task : oldTasks){
            parentIds.add(task.Project_Name__c);
            userIds.add(task.Assigned_To__c);
        }
        updateUser(userIds);
        Map<Id,Project2__c> queryTasks = QueryTasks(parentIds);
        Map<Id, Project2__c> updateProjectMap = new Map<Id, Project2__c>();
        for(Project_Task__c task : oldTasks){
            Project2__c proj = queryTasks.get(task.Project_Name__c);
            Integer totalCount = proj.Project_Tasks__r.size();
            Integer completedCount = getCompletedCount(proj.Project_Tasks__r);
            Project2__c temp = new Project2__c(Id = task.Project_Name__c);
            temp.Total_Tasks__c = totalCount;
            temp.Completed_Tasks__c = completedCount;
            temp.Name = proj.Name;
            if(totalCount == completedCount && !proj.Name.endsWith(' - Completed')) temp.Name = proj.Name + ' - Completed';
            if((totalCount != completedCount && proj.Name.endsWith(' - Completed')) || (totalCount == completedCount && totalCount == 0)) temp.Name = proj.Name.removeEnd(' - Completed');
            updateProjectMap.put(task.Project_Name__c, temp);
        }
        if(!updateProjectMap.isEmpty()){
            database.update(updateProjectMap.values(), false);
        }
    }
    
    public static void handleUndelete(List<Project_Task__c> newTasks){
        Set<Id> parentIds = new Set<Id>();
        for(Project_Task__c newRec : newTasks){
            parentIds.add(newRec.Project_Name__c);
        }
        Map<Id,Project2__c> queryTasks = QueryTasks(parentIds);
        Map<Id, Project2__c> updateProjectMap = new Map<Id, Project2__c>();
        for(Id projId : parentIds){
            Project2__c proj = queryTasks.get(projId);
            Integer totalCount = proj.Project_Tasks__r.size();
            Integer completedCount = getCompletedCount(proj.Project_Tasks__r);
            Project2__c temp = new Project2__c(Id = projId);
            temp.Total_Tasks__c = totalCount;
            temp.Completed_Tasks__c = completedCount;
            temp.Name = proj.Name;
            if(totalCount == completedCount && totalCount > 0 && !proj.Name.endsWith(' - Completed')) temp.Name = proj.Name + ' - Completed';
            if(totalCount != completedCount) temp.Name = proj.Name.endsWith(' - Completed') ? proj.Name.removeEnd(' - Completed') : proj.Name;
            updateProjectMap.put(projId, temp);
        }
        if(!updateProjectMap.isEmpty()){
            database.update(updateProjectMap.values(), false);
        }
    }
}