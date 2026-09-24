public with sharing class AccountRateCardHelper {
    
    //Method to populate the rate on account record at the time of account insertion, based on start date and end date.
    public static void handleInsert(List<Account> newAccount) {

        Set<Id> accountIds = new Map<Id, Account>(newAccount).keySet();
        
        //calculateRate(accountIds);
        //The above commented line was used to call the future method execution
        
        callQueueableExecution(accountIds);

    }

    //Method to update the rate on account record at the time of account updation, only if either the start date or the end date is changed.
    public static void handleUpdate(List<Account> newAccount, Map<Id, Account> oldAccountMap) {
                
        Set<Id> accountsToUpdate = new Set<Id>();

        for (Account acc : newAccount){
            
            //check if either the start date or end date of the account record is changed
            if(acc.Start_Date__c != oldAccountMap.get(acc.Id).Start_Date__c || acc.End_Date__c != oldAccountMap.get(acc.Id).End_Date__c){
                accountsToUpdate.add(acc.Id);
            }

        }

        if (!accountsToUpdate.isEmpty()){
            
            //calculateRate(accountsToUpdate);
            //The above commented line was used to call the future method execution
        
            callQueueableExecution(accountsToUpdate);
        }

    }

    public static void callQueueableExecution(Set<Id> accountIds) {
        System.enqueueJob(new AccountRateCardQueueable(accountIds));
    }

    /*
    
    @future
    //This method holds the core logic
    public static void calculateRate(Set<Id> accountIds){

        try {

            List<Account> accountList = [SELECT Id, Start_Date__c, End_Date__c FROM Account WHERE Id IN :accountIds];

            //variables to track the widest date range across the entire batch of accounts
            Date earliestStartDate;
            Date latestEndDate;

            for (Account currentAccount : accountList) {
                
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

            for (Account currentAccount : accountList) {

                Decimal totalRate = 0;

                //Detecting partial coverage
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
                    
                    //no Rate Card overlapped the Account's date range at all
                    accountToUpdate.Rate__c = null;
                    accountToUpdate.Rate_Card_Error__c = RateCardConstants.noRateCardFoundError;

                } else if (totalCoveredDays < totalAccountDays) {
                    
                    //some, but not all, of the Account's date range is covered by a Rate Card
                    accountToUpdate.Rate__c = totalRate;
                    accountToUpdate.Rate_Card_Error__c = RateCardConstants.partialRateCardError;

                } else {
                    
                    //the entire Account date range is covered by one or more Rate Cards
                    accountToUpdate.Rate__c = totalRate;
                    accountToUpdate.Rate_Card_Error__c = null;

                }
                
                accountsToSave.add(accountToUpdate);
            }

            update accountsToSave;

        } catch (Exception e){

            //Logs the technical error in the console log, and lets it surface to the user with a clear message.
            System.debug('AccountRateCardHelper.calculateRate failed: ' + e.getMessage());
            markAccountsAsFailed(accountIds);
            
            //throw new AccountRateCardException(RateCardConstants.rateCalculationFailure);

        }
             
    }

    private static void markAccountsAsFailed(Set<Id> accountIds) {

        List<Account> accountsToMarkFailed = new List<Account>();

        for (Id accountId : accountIds) {
            accountsToMarkFailed.add(new Account(
                Id = accountId,
                Rate__c = null,
                Rate_Card_Error__c = RateCardConstants.rateCalculationFailure
            ));
        }

        update accountsToMarkFailed;
    }
    */

    /*
    public class AccountRateCardException extends Exception {

    }
    */
}