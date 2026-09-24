global class QuoteMcpGet {

    global class GetQuotesRequest {
        @InvocableVariable(required=true description='Exact Opportunity Name to fetch quotes for.')
        global String opportunityName;
    }

    global class QuoteLineRow {
        @InvocableVariable global String quoteNumber;
        @InvocableVariable global String productName;
        @InvocableVariable global Decimal quantity;
        @InvocableVariable global Decimal discountPercent;
        @InvocableVariable global Decimal unitPrice;
        @InvocableVariable global Decimal lineTotal;
    }

    global class QuoteSummaryRow {
        @InvocableVariable global String quoteId;
        @InvocableVariable global String quoteNumber;
        @InvocableVariable global String quoteName;
        @InvocableVariable global String status;
        @InvocableVariable global Date startDate;
        @InvocableVariable global Date expirationDate;
        @InvocableVariable global Decimal grandTotal;
    }

    global class GetQuotesResult {
        @InvocableVariable global Boolean isSuccess;
        @InvocableVariable global String message;
        @InvocableVariable global String opportunityId;
        @InvocableVariable global String opportunityName;
        @InvocableVariable global String opportunityStage;
        @InvocableVariable global List<QuoteSummaryRow> quotes;
        @InvocableVariable global List<QuoteLineRow> lines;
    }

    @InvocableMethod(label='Get Quotes' description='Retrieves all Quotes and their product lines under a given Opportunity, by exact Opportunity Name.')
    global static List<GetQuotesResult> getQuotes(List<GetQuotesRequest> reqs) {
        List<GetQuotesResult> results = new List<GetQuotesResult>();

        for (GetQuotesRequest req : reqs) {
            GetQuotesResult res = new GetQuotesResult();

            List<Opportunity> opps = [SELECT Id, Name, StageName FROM Opportunity WHERE Name = :req.opportunityName LIMIT 2];
            if (opps.isEmpty()) {
                res.isSuccess = false;
                res.message = 'No Opportunity found named "' + req.opportunityName + '".';
                results.add(res);
                continue;
            }
            if (opps.size() > 1) {
                res.isSuccess = false;
                res.message = 'Multiple Opportunities are named "' + req.opportunityName + '". Ask the user to clarify which one.';
                results.add(res);
                continue;
            }
            Opportunity opp = opps[0];

            List<Quote> quoteRecords = [SELECT Id, QuoteNumber, Name, Status, Start_Date__c, ExpirationDate, GrandTotal FROM Quote WHERE OpportunityId = :opp.Id ORDER BY CreatedDate DESC];

            List<QuoteSummaryRow> summaries = new List<QuoteSummaryRow>();
            List<QuoteLineRow> allLines = new List<QuoteLineRow>();

            if (!quoteRecords.isEmpty()) {
                Set<Id> quoteIds = new Set<Id>();
                for (Quote q : quoteRecords) quoteIds.add(q.Id);

                List<QuoteLineItem> qlis = [SELECT QuoteId, Quantity, Discount, UnitPrice, TotalPrice, Product2.Name, Quote.QuoteNumber FROM QuoteLineItem WHERE QuoteId IN :quoteIds];
                for (QuoteLineItem qli : qlis) {
                    QuoteLineRow row = new QuoteLineRow();
                    row.quoteNumber = qli.Quote.QuoteNumber;
                    row.productName = qli.Product2.Name;
                    row.quantity = qli.Quantity;
                    row.discountPercent = qli.Discount;
                    row.unitPrice = qli.UnitPrice;
                    row.lineTotal = qli.TotalPrice;
                    allLines.add(row);
                }

                for (Quote q : quoteRecords) {
                    QuoteSummaryRow s = new QuoteSummaryRow();
                    s.quoteId = q.Id;
                    s.quoteNumber = q.QuoteNumber;
                    s.quoteName = q.Name;
                    s.status = q.Status;
                    s.startDate = q.Start_Date__c;
                    s.expirationDate = q.ExpirationDate;
                    s.grandTotal = q.GrandTotal;
                    summaries.add(s);
                }
            }

            res.isSuccess = true;
            res.message = quoteRecords.size() + ' quote(s) found.';
            res.opportunityId = opp.Id;
            res.opportunityName = opp.Name;
            res.opportunityStage = opp.StageName;
            res.quotes = summaries;
            res.lines = allLines;
            results.add(res);
        }
        return results;
    }
}