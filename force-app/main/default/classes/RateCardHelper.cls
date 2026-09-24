public with sharing class RateCardHelper {
    
    //Validates that newly inserted records do not overlap with each other, or with records already saved in the database
    public static void handleBeforeInsert(List<Rate_Card__c> newRecords) {

        try {
            
            List<Rate_Card__c> existingRateCardList = [SELECT Id, Start_Date__c, End_Date__c FROM Rate_Card__c];
            overlapCheck(newRecords, existingRateCardList);

        } catch (Exception e){

            System.debug('RateCardHelper.handleInsert failed: ' + e.getMessage());
            throw new RateCardValidationException(RateCardConstants.rateCardValidationFailure);

        }

    }

    //Validates that updated records do not overlap with each other, or with records already saved in the database. Only records whose Start Date or End Date actually changed are validated.
    public static void handleBeforeUpdate(Map<Id, Rate_Card__c> oldRecords, List<Rate_Card__c> newRecords){

        try {

            List<Rate_Card__c> existingRateCardList = [SELECT Id, Start_Date__c, End_Date__c FROM Rate_Card__c WHERE Id NOT IN :oldRecords.keySet()];
            List<Rate_Card__c> updatedDateRecords = new List<Rate_Card__c>();

            for (Rate_Card__c currentRecord : newRecords) {
                Rate_Card__c previousRateCard = oldRecords.get(currentRecord.Id);

                Boolean startDateChanged = currentRecord.Start_Date__c != previousRateCard.Start_Date__c;
                Boolean endDateChanged = currentRecord.End_Date__c != previousRateCard.End_Date__c;

                if (startDateChanged || endDateChanged) {
                    updatedDateRecords.add(currentRecord);
                }
            }

            if (!updatedDateRecords.isEmpty()) {
                overlapCheck(updatedDateRecords, existingRateCardList);
            }

        } catch (Exception e){

            System.debug('RateCardHelper.validateOverlapOnUpdate failed: ' + e.getMessage());
            throw new RateCardValidationException(RateCardConstants.rateCardValidationFailure);

        }

    }

    //This method blocks the deletion of a Rate Card that is currently in use by one or more Account records
    public static void handleBeforeDelete(List<Rate_Card__c> oldRecords) {

        try {
            
            //variables to track the widest date range across the entire batch of accounts
            Date earliestStartDate;
            Date latestEndDate;

            for (Rate_Card__c currentRateCard : oldRecords) {
                if (earliestStartDate == null || currentRateCard.Start_Date__c < earliestStartDate) {
                    earliestStartDate = currentRateCard.Start_Date__c;
                }
                if (latestEndDate == null || currentRateCard.End_Date__c > latestEndDate) {
                    latestEndDate = currentRateCard.End_Date__c;
                }
            }

            List<Account> dependentAccountList = [SELECT Id, Start_Date__c, End_Date__c FROM Account WHERE Start_Date__c <= :latestEndDate AND End_Date__c >= :earliestStartDate];

            for (Rate_Card__c currentRateCard : oldRecords) {
                
                for (Account currentAccount : dependentAccountList) {

                    Boolean overlaps = currentAccount.Start_Date__c <= currentRateCard.End_Date__c && currentRateCard.Start_Date__c <= currentAccount.End_Date__c;

                    if (overlaps) {
                        currentRateCard.addError(RateCardConstants.rateCardDeletionError);
                        break;
                    }

                }

            }

        } catch (Exception e) {
            
            System.debug('RateCardHelper.handleBeforeDelete failed: ' + e.getMessage());
            throw new RateCardValidationException(RateCardConstants.rateCardValidationFailure);

        }

    }

    //When new Rate Cards are inserted, finds any Account currently showing noRateCardFoundError or partialRateCardError whose date range overlaps the new Rate Cards, and recalculates them.
    public static void handleAfterInsert(List<Rate_Card__c> newRecords){

        try {

            //variables to track the widest date range across the entire batch of accounts
            Date earliestStartDate;
            Date latestEndDate;

            for (Rate_Card__c currentRateCard : newRecords) {
                if (earliestStartDate == null || currentRateCard.Start_Date__c < earliestStartDate) {
                    earliestStartDate = currentRateCard.Start_Date__c;
                }
                if (latestEndDate == null || currentRateCard.End_Date__c > latestEndDate) {
                    latestEndDate = currentRateCard.End_Date__c;
                }
            }

            //only Accounts previously flagged as fully or partially unmatched could possibly need recalculating here
            List<Account> accountsToRecalculate = [SELECT Id, Start_Date__c, End_Date__c FROM Account WHERE (Rate_Card_Error__c = :RateCardConstants.noRateCardFoundError OR Rate_Card_Error__c = :RateCardConstants.partialRateCardError) AND Start_Date__c <= :latestEndDate AND End_Date__c >= :earliestStartDate];

            if (!accountsToRecalculate.isEmpty()) {
                AccountRateCardHelper.callQueueableExecution(new Map<Id, Account>(accountsToRecalculate).keySet());
            }

        } catch (Exception e){

            System.debug('RateCardHelper.handleAfterInsert failed: ' + e.getMessage());
            throw new RateCardValidationException(RateCardConstants.rateCardValidationFailure);

        }

    }
    
    //When a Rate Card's 'Rate' value changes, this method finds every Account whose date range could overlap that Rate Card, and asks AccountRateCardHelper to recalculate their Rate so the new value is reflected immediately.
    public static void handleAfterUpdate(Map<Id, Rate_Card__c> oldRecords, List<Rate_Card__c> newRecords){

        try {

            List<Rate_Card__c> updatedRateCards = new List<Rate_Card__c>();
            
            for (Rate_Card__c currentRateCard : newRecords) {
                Rate_Card__c previousRateCard = oldRecords.get(currentRateCard.Id);

                if (currentRateCard.Rate__c != previousRateCard.Rate__c) {
                    updatedRateCards.add(currentRateCard);
                }
            }

            //variables to track the widest date range across the entire batch of accounts
            Date earliestStartDate;
            Date latestEndDate;

            for (Rate_Card__c currentRateCard : updatedRateCards) {
                if (earliestStartDate == null || currentRateCard.Start_Date__c < earliestStartDate) {
                    earliestStartDate = currentRateCard.Start_Date__c;
                }
                if (latestEndDate == null || currentRateCard.End_Date__c > latestEndDate) {
                    latestEndDate = currentRateCard.End_Date__c;
                }
            }

            //fetching every Account whose date range could overlap any of the changed Rate Cards
            List<Account> accountsToRecalculate = [SELECT Id, Start_Date__c, End_Date__c FROM Account WHERE Start_Date__c <= :latestEndDate AND End_Date__c >= :earliestStartDate];

            if (!accountsToRecalculate.isEmpty()) {
                
                //AccountRateCardHelper.calculateRate(new Map<Id, Account>(accountsToRecalculate).keySet());
                //The above commented line was used to call the future method execution

                AccountRateCardHelper.callQueueableExecution(new Map<Id, Account>(accountsToRecalculate).keySet());
            }

        } catch (Exception e){

            System.debug('RateCardHelper.handleAfterUpdate failed: ' + e.getMessage());
            throw new RateCardValidationException(RateCardConstants.rateCardValidationFailure);

        }

    }

    //Compares each record for dates overlap validation against the existing database records and against each other (if in the same batch), adding an error where an overlap is found
    private static void overlapCheck(List<Rate_Card__c> recordsToValidate, List<Rate_Card__c> existingRateCardList){

        for (Integer i = 0; i < recordsToValidate.size(); i++){
            
            Rate_Card__c currentRecord = recordsToValidate[i];
            
            //checks for dates overlap against the records already saved in the database
            for (Rate_Card__c existingRateCard : existingRateCardList) {
                if (datesOverlap(currentRecord, existingRateCard)) {
                    currentRecord.addError(RateCardConstants.rateCardOverlapError);
                    break;
                }
            }

            //checks for overlaps among the records in the current batch itself 
            for (Integer j = i + 1; j < recordsToValidate.size(); j++) {
                Rate_Card__c otherRateCard = recordsToValidate[j];
                if (datesOverlap(currentRecord, otherRateCard)) {
                    otherRateCard.addError(RateCardConstants.rateCardOverlapError);
                }
            }

        }

    }

    //Returns true if the two Rate Card records' date ranges overlap at all, inclusive of boundary dates
    private static Boolean datesOverlap(Rate_Card__c currentRecord, Rate_Card__c secondRateCard) {
        if (currentRecord.Start_Date__c <= secondRateCard.End_Date__c && secondRateCard.Start_Date__c <= currentRecord.End_Date__c){
            return true;
        } else {
            return false;
        }
    }
    
    public class RateCardValidationException extends Exception {

    }

}