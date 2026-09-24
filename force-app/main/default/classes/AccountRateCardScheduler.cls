public with sharing class AccountRateCardScheduler implements Schedulable {
    
    public static final String jobName = 'Account Rate Card Recalculation Schedule';
    
    //this expression fires once every single day, at midnight.
    //Cron Expression - seconds  minutes  hours  day_of_the_month  month  day_of_the_week
    public static final String cronExpression = '0 0 0 * * ?';
    
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AccountRateCardBatchable(), 200);
    }

    //We have to call this method once in Anonymous Window to Activate the recurring scheduled job
    public static void scheduleJob() {
        System.schedule(jobName, cronExpression, new AccountRateCardScheduler());
    }

}