@RestResource(urlMapping='/webhook/v1/*')
global without sharing class ExternalWebhookReceiver {

    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        // Step 1: check the secret
        String secretFromHeader = req.headers.get('X-Webhook-Secret');
        Webhook_Config__mdt config = Webhook_Config__mdt.getInstance('External_System');

        if (secretFromHeader == null || secretFromHeader != config.Shared_Secret__c) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('{"error":"unauthorized"}');
            return;
        }

        // Step 2: read the JSON that was sent
        String jsonText = req.requestBody.toString();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonText);

        // Step 3: build an Account from the JSON
        Account acc = new Account();
        acc.External_Source_Id__c = (String) data.get('id');
        acc.Name = (String) data.get('name');
        acc.Phone = (String) data.get('phone');

        // Step 4: save it (creates new, or updates if the external id already exists)
        upsert acc External_Source_Id__c;

        res.statusCode = 201;
    }

    @HttpPatch
    global static void handlePatch() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String secretFromHeader = req.headers.get('X-Webhook-Secret');
        Webhook_Config__mdt config = Webhook_Config__mdt.getInstance('External_System');

        if (secretFromHeader == null || secretFromHeader != config.Shared_Secret__c) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('{"error":"unauthorized"}');
            return;
        }

        String jsonText = req.requestBody.toString();
        Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonText);

        Account acc = new Account();
        acc.External_Source_Id__c = (String) data.get('id');
        acc.Name = (String) data.get('name');
        acc.Phone = (String) data.get('phone');

        upsert acc External_Source_Id__c;

        res.statusCode = 200;
    }

    @HttpDelete
    global static void handleDelete() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        String secretFromHeader = req.headers.get('X-Webhook-Secret');
        Webhook_Config__mdt config = Webhook_Config__mdt.getInstance('External_System');

        if (secretFromHeader == null || secretFromHeader != config.Shared_Secret__c) {
            res.statusCode = 401;
            res.responseBody = Blob.valueOf('{"error":"unauthorized"}');
            return;
        }

        // Pull the external id off the end of the URL
        String url = req.requestURI;
        Integer positionOfLastSlash = url.lastIndexOf('/');
        String externalId = url.substring(positionOfLastSlash + 1);

        List<Account> accountsFound = [
            SELECT Id FROM Account WHERE External_Source_Id__c = :externalId
        ];

        if (accountsFound.size() == 0) {
            res.statusCode = 404;
            return;
        }

        delete accountsFound[0];
        res.statusCode = 204;
    }
}