public with sharing class AccountRateCardBatchable implements Database.Batchable<SObject>, Database.Stateful {
    
    private Integer totalProcessed = 0;
    private Integer totalSuccess = 0;
    private Integer totalFailure = 0;
    
    public Database.QueryLocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([SELECT Id, Start_Date__c, End_Date__c FROM Account WHERE Start_Date__c != null AND End_Date__c != null]);

    }

    public void execute (Database.BatchableContext bc, List<Account> scope) {

        try {
            
            //variables to track the widest date range across the entire batch of accounts
            Date earliestStartDate;
            Date latestEndDate;

            for (Account currentAccount : scope) {
                if (earliestStartDate == null || currentAccount.Start_Date__c < earliestStartDate) {
                    earliestStartDate = currentAccount.Start_Date__c;
                }
                if (latestEndDate == null || currentAccount.End_Date__c > latestEndDate) {
                    latestEndDate = currentAccount.End_Date__c;
                }
            }

            //fetching every Rate Card that could possibly match with any account's date range in this batch
            List<Rate_Card__c> rateCardList = [SELECT Id, Start_Date__c, End_Date__c, Rate__c FROM Rate_Card__c WHERE Start_Date__c <= :latestEndDate AND End_Date__c >= :earliestStartDate];

            List<Account> accountsToSave = new List<Account>();
            Integer chunkSuccessCount = 0;
            Integer chunkFailureCount = 0;

            for (Account currentAccount : scope) {

                Decimal totalRate = 0;

                //detecting partial coverage
                Integer totalAccountDays = currentAccount.Start_Date__c.daysBetween(currentAccount.End_Date__c) + 1;
                Integer totalCoveredDays = 0;

                for (Rate_Card__c currentRateCard : rateCardList) {
                    
                    Date overlapStartDate = currentAccount.Start_Date__c > currentRateCard.Start_Date__c ? currentAccount.Start_Date__c : currentRateCard.Start_Date__c;
                    Date overlapEndDate = currentAccount.End_Date__c < currentRateCard.End_Date__c ? currentAccount.End_Date__c : currentRateCard.End_Date__c;

                    Boolean rangesOverlap = overlapStartDate <= overlapEndDate;
                    
                    if (!rangesOverlap) {
                        //this means there's no real overlap at all and the two ranges are completely apart
                        continue;
                    }

                    Integer overlapDayCount = overlapStartDate.daysBetween(overlapEndDate) + 1;
                    Integer daysInRateCardMonth = Date.daysInMonth(currentRateCard.Start_Date__c.year(), currentRateCard.Start_Date__c.month());
                    Decimal dailyRate = currentRateCard.Rate__c / daysInRateCardMonth;

                    totalRate += dailyRate * overlapDayCount;
                    totalCoveredDays += overlapDayCount;
                }

                Account accountToUpdate = new Account(Id = currentAccount.Id);

                if (totalCoveredDays == 0) {
                    
                    //no Rate Card overlapped the Account's date range at all - counted as a failure
                    accountToUpdate.Rate__c = null;
                    accountToUpdate.Rate_Card_Error__c = RateCardConstants.noRateCardFoundError;
                    chunkFailureCount++;

                } else if (totalCoveredDays < totalAccountDays) {
                    
                    //partial coverage - a Rate was still calculated, so counted as a success
                    accountToUpdate.Rate__c = totalRate;
                    accountToUpdate.Rate_Card_Error__c = RateCardConstants.partialRateCardError;
                    chunkSuccessCount++;

                } else {
                    
                    //the entire Account date range is covered by one or more Rate Cards
                    accountToUpdate.Rate__c = totalRate;
                    accountToUpdate.Rate_Card_Error__c = null;
                    chunkSuccessCount++;
                    
                }
                
                accountsToSave.add(accountToUpdate);
            }

            update accountsToSave;

            totalProcessed += scope.size();
            totalSuccess += chunkSuccessCount;
            totalFailure += chunkFailureCount;

        } catch (Exception e){

            //Logs the technical error in the console log, and lets it surface to the user with a clear message.
            System.debug('Batch Execution failed: ' + e.getMessage());
            markAccountsAsFailed(scope);
            totalProcessed += scope.size();
            totalFailure += scope.size();

        }

    }

    public void finish(Database.BatchableContext bc) {

        AsyncApexJob batchJob = [SELECT Id, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()];

        String emailBody = 'The Account\'s Rate calculation batch has completed.\n\n'
            + 'Total Account Records Processed: ' + totalProcessed + '\n'
            + 'Total Account Records where Rate was calculated successfully: ' + totalSuccess + '\n'
            + 'Total Account Records where Rate calculation failed: ' + totalFailure;

        Messaging.SingleEmailMessage summaryMail = new Messaging.SingleEmailMessage();
        summaryMail.setToAddresses(new List<String>{ batchJob.CreatedBy.Email });
        summaryMail.setSubject('Account Rate Card Processing - Batch Completion Summary');
        summaryMail.setPlainTextBody(emailBody);

        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ summaryMail });
        
    }

    private void markAccountsAsFailed(List<Account> scope) {

        List<Account> accountsToMarkFailed = new List<Account>();

        for (Account currentAccount : scope) {
            accountsToMarkFailed.add(new Account(
                Id = currentAccount.Id,
                Rate__c = null,
                Rate_Card_Error__c = RateCardConstants.rateCalculationFailure
            ));
        }

        update accountsToMarkFailed;
    }

}