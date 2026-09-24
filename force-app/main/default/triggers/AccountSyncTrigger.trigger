trigger AccountSyncTrigger on Account (after insert, after update) {
    AccountSyncHandler.handle(Trigger.new, Trigger.oldMap, Trigger.isInsert);
}