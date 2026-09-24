public class TelegramService {

    private static String getToken() {
        Telegram_Config__mdt config = [
            SELECT Bot_Token__c FROM Telegram_Config__mdt 
            WHERE DeveloperName = 'Default' LIMIT 1
        ];
        return config.Bot_Token__c;
    }

    public static void sendMessage(String chatId, String messageText) {
        String token = getToken();
        String endpoint = 'callout:Telegram_Bot/bot' + token + '/sendMessage';

        Map<String, Object> body = new Map<String, Object>{
            'chat_id' => chatId,
            'text' => messageText
        };

        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() != 200) {
                System.debug('Telegram error: ' + res.getBody());
            } else {
                System.debug('Message sent: ' + res.getBody());
            }
        } catch (Exception e) {
            System.debug('Callout failed: ' + e.getMessage());
        }
    }

    @future(callout=true)
    public static void sendMessageAsync(String chatId, String messageText) {
        sendMessage(chatId, messageText);
    }

    @InvocableMethod(label='Send Telegram Message' description='Sends a message to a Telegram chat')
    public static void sendMessageInvocable(List<TelegramRequest> requests) {
        for (TelegramRequest r : requests) {
            sendMessageAsync(r.chatId, r.messageText);
        }
    }

    public class TelegramRequest {
        @InvocableVariable(required=true)
        public String chatId;
        @InvocableVariable(required=true)
        public String messageText;
    }
}