//@isTest
public class TestDataFactory {
    
    public static List<Account> createAccount(Integer recordCount){
        
        List<Account> accounts = new List<Account>();
        
        for(Integer i = 0; i < recordCount; i++){
            accounts.add(new Account (
                name = 'Test Account' + i,
                Start_Date__c = Date.newInstance(2026, 1, 1),
                End_Date__c = Date.newInstance(2026, 1, 15)
            ));
        }
        
        return accounts;
    }

    public static List<Rate_Card__c> createRateCards(Integer recordCount) {
        
        List<Rate_Card__c> rateCards = new List<Rate_Card__c>();
        
        for (Integer i = 0; i < recordCount; i++) {
            rateCards.add(new Rate_Card__c(
                Start_Date__c = Date.newInstance(2026, 1, 1).addMonths(i),
                End_Date__c = Date.newInstance(2026, 1, 1).addMonths(i).addDays(27),
                Rate__c = 310.00 
            ));
        }
        
        return rateCards;

    }

    public static List<Opportunity> createOpportunity(Integer recordCount){
        
        List<Opportunity> opps = new List<Opportunity>();
        
        for(Integer i = 0; i < recordCount; i++){
            opps.add(new Opportunity (name = 'Test Opp', stageName = 'Prospecting', closeDate = System.Today()));
        }
        
        return opps;
    }

    public static void createEmailTemplate(){
        
        Folder folder = [SELECT Id FROM Folder WHERE Type = 'Email' LIMIT 1];
        
        EmailTemplate template = new EmailTemplate(
            DeveloperName = 'Contact_Email_Template',
            Name = 'Contact Email Template',
            TemplateType = 'text',
            FolderId = folder.Id,
            Subject = 'Welcome',
            Body = 'Hello {!Contact.FirstName}, welcome!'
        );
        
        insert template;

    }

    public static void createOrgWideEmailAddress() {
        
        OrgWideEmailAddress owea = new OrgWideEmailAddress(
            Address = 'kunj.agarwal.243@gmail.com',
            DisplayName = 'Test OWEA'
        );

    }

    public static List<Contact> createContacts(Integer count) {
        
        List<Contact> contacts = new List<Contact>();
        
        for (Integer i = 0; i < count; i++) {
            Contact con = new Contact(
                LastName = 'TestContact' + i,
                Email = 'testcontact' + i + '@example.com'
            );
            contacts.add(con);
        }
        
        return contacts;
    }

    public static List<Incentive__c> createIncentive(Integer count){
        
        List<Incentive__c> incentives = new List<Incentive__c>();
        
        for(Integer i = 0; i < count; i++){
            Incentive__c inc = new Incentive__c(
                Name = 'Test Incentive ' + i
                //Amount__c = (Integer)Math.Random() * 1200
            );
            incentives.add(inc);
        }
        
        return incentives;
    }

}