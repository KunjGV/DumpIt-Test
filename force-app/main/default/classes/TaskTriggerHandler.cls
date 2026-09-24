public class TaskTriggerHandler {
    public static void beforeDelete(List<Task> taskRecord){
        TaskTriggerHelper.taskDeleteAccess(taskRecord);
    }
}