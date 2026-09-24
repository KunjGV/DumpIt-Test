public class AccountSyncQueueable implements Queueable, Database.AllowsCallouts {

    private List<Account> records;
    private String mode; 

    public AccountSyncQueueable(List<Account> records, String mode) {
        this.records = records;
        this.mode = mode;
    }

    public void execute(QueueableContext ctx) {
        Sync_Config__mdt cfg = Sync_Config__mdt.getInstance('OrgB_Sync');
        List<Integration_Log__c> failures = new List<Integration_Log__c>();
        List<Account> toUpdateWithNewId = new List<Account>();
        Boolean isCreate = (mode == 'CREATE');

        for (Account acc : records) {
            Map<String, Object> body = new Map<String, Object>{
                'Name' => acc.Name,
                'Phone' => acc.Phone,
                'BillingCity' => acc.BillingCity,
                'Industry' => acc.Industry,
                'Type' => acc.Type
            };
            if (isCreate) {
                body.put('Org_A_Record_Id__c', acc.Id);
            }

            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json');
            req.setBody(JSON.serialize(body));

            if (isCreate) {
                req.setEndpoint('callout:' + cfg.Named_Credential__c + '/services/data/' + cfg.Target_API_Version__c + '/sobjects/Account');
                req.setMethod('POST');
            } else {
                req.setEndpoint('callout:' + cfg.Named_Credential__c + '/services/data/' + cfg.Target_API_Version__c + '/sobjects/Account/' + acc.Org_B_Record_Id__c);
                req.setMethod('PATCH');
            }

            Http http = new Http();
            HttpResponse res = http.send(req);
            Integer status = res.getStatusCode();

            if (isCreate && status == 201) {
                
                Map<String, Object> resBody = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                Account toUpdate = new Account(Id = acc.Id, Org_B_Record_Id__c = (String) resBody.get('id'));
                toUpdateWithNewId.add(toUpdate);
                
            } else if (status >= 300) {
                failures.add(logFailure(status, res.getBody(), acc.Id, mode));
            }
        }

        if (!toUpdateWithNewId.isEmpty()) {
            update toUpdateWithNewId;
        }
        if (!failures.isEmpty()) {
            insert failures;
        }
    }

    private Integration_Log__c logFailure(Integer status, String responseBody, Id recordId, String operation) {
        return new Integration_Log__c(
            Status_Code__c = status,
            Response_Body__c = responseBody.abbreviate(5000),
            Object_Type__c = 'Account',
            Direction__c = 'OrgA_to_OrgB_' + operation,
            Record_Id__c = recordId,
            Created_At__c = System.now()
        );
    }
}