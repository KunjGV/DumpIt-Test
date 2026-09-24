public class ContactTriggerSendEmailHelper {
    public static void sendEmail(List<Contact> newContact){
        EmailTemplate template = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Contact_Email_Template' LIMIT 1];
        system.debug(template);
        
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'kunj.agarwal.243@gmail.com' LIMIT 1];
        system.debug(owea);
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for (Contact con: newContact){
            if(con.Email != null){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                if(!owea.isEmpty()){
                    mail.setOrgWideEmailAddressId(owea[0].Id);
                }
                //mail.setToAddresses(new List<String>{con.Email});
                mail.setTemplateId(template.Id);
                mail.setTargetObjectId(con.Id);
                emailList.add(mail);
            }
        }
        
        if(!emailList.isEmpty()){
            Messaging.sendEmail(emailList);
            System.debug('Email Sent Successfully!');
        }
    }
}