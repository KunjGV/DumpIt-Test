public class TaskTriggerHelper {
    public static void taskDeleteAccess(List<Task> taskRecord){
        Id currentUserProfileId = UserInfo.getProfileId();
        String currentUserProfileName = [SELECT Name FROM Profile WHERE Id =:currentUserProfileId].Name;
        for(Task tsk : taskRecord){
            if(currentUserProfileName != 'System Administrator'){
                tsk.addError('The record could not be deleted as you do not have the required permissions. Ask your administrator for any help!');
            }
            break;
        }
    }
}