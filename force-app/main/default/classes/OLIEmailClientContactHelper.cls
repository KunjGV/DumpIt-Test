public class OLIEmailClientContactHelper {
    public static void mailContact(List<OpportunityLineItem> newOLI){
        
        Set<Id> oliIds = new Set<Id>();
        
        for(OpportunityLineItem thisOLI : newOLI){
            oliIds.add(thisOLI.Id);
        }
        List<OpportunityLineItem> requiredOLIs = [SELECT id, Opportunity.Account.Client_Contact__c FROM OpportunityLineItem WHERE Opportunity.Account.Client_Contact__r.Email != null AND Id IN :oliIds];
        EmailTemplate getTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'Client_Contact_Template' LIMIT 1];
        OrgWideEmailAddress[] owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'kunj.agarwal.243@gmail.com' LIMIT 1];
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        for(OpportunityLineItem OLIs : requiredOLIs){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setOrgWideEmailAddressId(owea[0].Id);
            mail.setTemplateId(getTemplate.Id);
            mail.setTargetObjectId(OLIs.Opportunity.Account.Client_Contact__c);
            mail.setWhatId(OLIs.Id);
            emailList.add(mail);
        }
        if(!emailList.isEmpty()){
            Messaging.sendEmail(emailList);
        }

    }
}