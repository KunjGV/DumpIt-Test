global class QuoteMcpCreate {

    global class ProductLineInput {
        @InvocableVariable(required=true description='Exact Product Name as it exists in the org, e.g. "Mac Laptop". Must be a value the user explicitly stated -- never invent a product.')
        global String productName;
        @InvocableVariable(required=true description='Quantity of this product. Must be a value the user explicitly stated -- never invent a quantity.')
        global Decimal quantity;
        @InvocableVariable(description='Discount percentage (0-100) on this line, only if the user explicitly stated one. Leave blank if not mentioned -- do not default to 0.')
        global Decimal discountPercent;
    }

    global class CreateQuoteRequest {
        @InvocableVariable(required=true description='Exact Opportunity Name as it exists in the org. Must be a value the user explicitly stated.')
        global String opportunityName;
        @InvocableVariable(description='Name for the new Quote. If the user did not specify one, leave blank -- it defaults to the Opportunity Name.')
        global String quoteName;
        @InvocableVariable(required=true description='Quote start date. Compute the actual calendar date from the user\'s phrasing (e.g. "today") using the current date -- do not ask the user for an ISO date if they gave a relative phrase.')
        global Date startDate;
        @InvocableVariable(required=true description='Quote expiration date. Compute the actual calendar date from the user\'s phrasing (e.g. "expires after a month" measured from the start date) -- do not ask the user for an ISO date if they gave a relative phrase.')
        global Date expirationDate;
        @InvocableVariable(required=true description='One entry per product to add. Product names and quantities must be values the user explicitly stated -- never invent products, quantities, or discounts.')
        global List<ProductLineInput> products;
    }

    global class LineRow {
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

    global class CreateQuoteResult {
        @InvocableVariable global Boolean isSuccess;
        @InvocableVariable global String message;
        @InvocableVariable global String opportunityId;
        @InvocableVariable global String opportunityName;
        @InvocableVariable global String opportunityStage;
        @InvocableVariable global List<QuoteSummaryRow> quotes;
        @InvocableVariable global List<LineRow> lines;
    }

    @InvocableMethod(label='Create Quote' description='Creates a Quote under an existing Opportunity and adds product lines to it. Requires the exact Opportunity Name, a start date, an expiration date, and at least one product with a name and quantity -- all must be values the user explicitly stated (dates may be computed from relative phrases like "today" or "in a month"). Never invent an Opportunity, product, quantity, or discount the user did not mention.')
    global static List<CreateQuoteResult> createQuote(List<CreateQuoteRequest> reqs) {
        List<CreateQuoteResult> results = new List<CreateQuoteResult>();

        for (CreateQuoteRequest req : reqs) {
            CreateQuoteResult res = new CreateQuoteResult();

            List<Opportunity> opps = [SELECT Id, Name, StageName, Pricebook2Id FROM Opportunity WHERE Name = :req.opportunityName LIMIT 2];
            if (opps.isEmpty()) {
                res.isSuccess = false;
                res.message = 'No Opportunity found named "' + req.opportunityName + '". Confirm the exact name with the user.';
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

            Id pricebookId = opp.Pricebook2Id;
            if (pricebookId == null) {
                List<Pricebook2> activePb = [SELECT Id, Name FROM Pricebook2 WHERE IsActive = true LIMIT 2];
                if (activePb.isEmpty()) {
                    res.isSuccess = false;
                    res.message = 'No Price Book is set on this Opportunity, and no active Price Book exists in this org. Set a Price Book on the Opportunity and try again.';
                    results.add(res);
                    continue;
                }
                if (activePb.size() > 1) {
                    res.isSuccess = false;
                    res.message = 'This Opportunity has no Price Book set, and multiple active Price Books exist in the org, so one cannot be chosen automatically. Ask the user which Price Book to use, or set one directly on the Opportunity, then try again.';
                    results.add(res);
                    continue;
                }
                pricebookId = activePb[0].Id;
            }

            if (req.products == null || req.products.isEmpty()) {
                res.isSuccess = false;
                res.message = 'At least one product is required to create a quote.';
                results.add(res);
                continue;
            }

            List<String> resolutionErrors = new List<String>();
            Map<String, PricebookEntry> entryByProductName = new Map<String, PricebookEntry>();
            for (ProductLineInput line : req.products) {
                if (String.isBlank(line.productName) || line.quantity == null || line.quantity <= 0) {
                    resolutionErrors.add('Product "' + line.productName + '" is missing a valid quantity.');
                    continue;
                }
                if (!entryByProductName.containsKey(line.productName)) {
                    List<PricebookEntry> entries = [SELECT Id, UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2.Name = :line.productName AND IsActive = true LIMIT 2];
                    if (entries.isEmpty()) {
                        resolutionErrors.add('Product "' + line.productName + '" was not found (or is not active) in the resolved Price Book.');
                        continue;
                    }
                    if (entries.size() > 1) {
                        resolutionErrors.add('Multiple active Price Book entries exist for product "' + line.productName + '". Ask the user to clarify.');
                        continue;
                    }
                    entryByProductName.put(line.productName, entries[0]);
                }
            }

            if (!resolutionErrors.isEmpty()) {
                res.isSuccess = false;
                res.message = 'Could not create the quote: ' + String.join(resolutionErrors, ' ');
                results.add(res);
                continue;
            }

            Savepoint sp = Database.setSavepoint();
            try {
                Quote q = new Quote(
                    OpportunityId  = opp.Id,
                    Name           = String.isNotBlank(req.quoteName) ? req.quoteName : opp.Name,
                    Pricebook2Id   = pricebookId,
                    Start_Date__c  = req.startDate,
                    ExpirationDate = req.expirationDate
                );
                insert q;

                List<QuoteLineItem> lineItems = new List<QuoteLineItem>();
                List<LineRow> lineResults = new List<LineRow>();
                Decimal grandTotal = 0;

                for (ProductLineInput line : req.products) {
                    PricebookEntry pbe = entryByProductName.get(line.productName);
                    lineItems.add(new QuoteLineItem(
                        QuoteId          = q.Id,
                        PricebookEntryId = pbe.Id,
                        Product2Id       = pbe.Product2Id,
                        Quantity         = line.quantity,
                        UnitPrice        = pbe.UnitPrice,
                        Discount         = line.discountPercent
                    ));

                    Decimal disc = line.discountPercent == null ? 0 : line.discountPercent;
                    Decimal lineTotal = (pbe.UnitPrice * (1 - disc / 100) * line.quantity).setScale(2);
                    grandTotal += lineTotal;

                    LineRow lr = new LineRow();
                    lr.quoteNumber = q.QuoteNumber;
                    lr.productName = line.productName;
                    lr.quantity = line.quantity;
                    lr.discountPercent = line.discountPercent;
                    lr.unitPrice = pbe.UnitPrice;
                    lr.lineTotal = lineTotal;
                    lineResults.add(lr);
                }
                insert lineItems;

                QuoteSummaryRow summary = new QuoteSummaryRow();
                summary.quoteId = q.Id;
                summary.quoteNumber = q.QuoteNumber;
                summary.quoteName = q.Name;
                summary.status = q.Status;
                summary.startDate = req.startDate;
                summary.expirationDate = req.expirationDate;
                summary.grandTotal = grandTotal.setScale(2);

                res.isSuccess = true;
                res.message = 'Quote created with ' + lineItems.size() + ' product line(s).';
                res.opportunityId = opp.Id;
                res.opportunityName = opp.Name;
                res.opportunityStage = opp.StageName;
                res.quotes = new List<QuoteSummaryRow>{ summary };
                res.lines = lineResults;
            } catch (Exception e) {
                Database.rollback(sp);
                res.isSuccess = false;
                res.message = 'Failed to create the quote: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}