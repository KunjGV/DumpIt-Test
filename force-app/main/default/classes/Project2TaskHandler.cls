public class Project2TaskHandler {
    public static void beforeInsert(List<Project_Task__c> newTasks){
        Project2TaskHelper.handleBeforeInsert(newTasks);
    }
    public static void afterInsert(List<Project_Task__c> newTasks){
        Project2TaskHelper.handleInsert(newTasks);
    }
    public static void beforeUpdate(List<Project_Task__c> newTasks, Map<Id, Project_Task__c> oldTaskMap){
        Project2TaskHelper.handleBeforeUpdate(newTasks, oldTaskMap);
    }
    public static void afterUpdate(List<Project_Task__c> newTasks, Map<Id, Project_Task__c> oldTaskMap){
        Project2TaskHelper.handleUpdate(newTasks, oldTaskMap);
    }
    public static void afterDelete(List<Project_Task__c> oldTasks){
        Project2TaskHelper.handleDelete(oldTasks);
    }
    public static void afterUndelete(List<Project_Task__c> newTasks){
        Project2TaskHelper.handleUndelete(newTasks);
    }
}