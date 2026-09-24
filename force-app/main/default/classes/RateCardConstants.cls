public with sharing class RateCardConstants {
    
    //Error message populated on Account.Rate_Card_Error__c when no Rate Card overlaps the Account's date range.
    public static final String noRateCardFoundError = 'No Rate Card Found';

    //Error message populated on Account.Rate_Card_Error__c when Rate Card coverage exists but doesn't span the Account's entire date range.
    public static final String partialRateCardError = 'Rate calculated is partial - Rate Card coverage does not span the entire Account date range.';

    //Error message added to a Rate Card record whose dates overlap another Rate Card.
    public static final String rateCardOverlapError = 'This Rate Card\'s dates overlap with an existing Rate Card.';

    //Error message shown when attempted deletion of a rate card which is being used by one or more accounts.
    public static final string rateCardDeletionError = 'This Rate Card cannot be deleted because it is currently in use by one or more Account records.';

    //Error message used when an unexpected exception occurs during rate calculation.
    public static final String rateCalculationFailure = 'An error occurred while calculating the Rate. Please contact your System Administrator.';

    //Error message used when an unexpected exception occurs during Rate Card validation.
    public static final String rateCardValidationFailure = 'An error occurred while validating the Rate Card. Please contact your System Administrator.';

}