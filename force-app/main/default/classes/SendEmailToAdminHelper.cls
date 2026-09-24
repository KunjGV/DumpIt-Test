public class SendEmailToAdminHelper {
    public static void sendEmail(List<Account> newAcc){
        Set<User> adminUser = new Set<User>();
        for(User admins : [SELECT Id, Email FROM User WHERE Profile.Name = 'System Administrator' AND isActive = true AND Email != null]){
            adminUser.add(admins);
        }
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'kunj.agarwal.243@gmail.com' LIMIT 1];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(User emails : adminUser){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('New Account Created');
            String body = 'An Account named ' + newAcc[0].Name + ' has been created in your Org. Please review if you were not informed beforehand.';
            email.setHtmlBody(body);
            email.setOrgWideEmailAddressId(owea[0].Id);
            email.setToAddresses(new List<String>{emails.Email});
            emailList.add(email);
        }
        Messaging.sendEmail(emailList);
    }
}