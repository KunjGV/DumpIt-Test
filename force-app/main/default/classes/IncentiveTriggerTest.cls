@IsTest
private class IncentiveTriggerTest {
    @TestSetup
    static void setupTestData() {
        List<Incentive__c> parents = TestDataFactory.createIncentive(1);
        parents[0].amount__c = 1200;
        insert parents;
    }
 
    @IsTest
    static void testParentInsertCreatesChildren() {
        Incentive__c parent = [SELECT Id FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        List<Incentive__c> children = [SELECT Id, amount__c, month__c FROM Incentive__c WHERE parent_incentive__c = :parent.Id];
        Assert.areEqual(12, children.size());
        Assert.areEqual(100, children[0].amount__c);
    }
 
    @IsTest
    static void testParentInsertZeroOrNullAmount() {
        List<Incentive__c> zeroAmountParent = TestDataFactory.createIncentive(1);
        insert zeroAmountParent;
        List<Incentive__c> children = [SELECT Id, amount__c FROM Incentive__c WHERE parent_incentive__c = :zeroAmountParent[0].Id];
        Assert.areEqual(12, children.size());
        Assert.areEqual(0, children[0].amount__c);
    }
 
    @IsTest
    static void testInvalidInsertPartialFields() {
        List<Incentive__c> invalidMonthOnly = TestDataFactory.createIncentive(1);
        invalidMonthOnly[0].month__c = 'January';
        Boolean exception1 = false;
        try { 
            insert invalidMonthOnly; 
        } catch (Exception e) { 
            exception1 = true; 
        }
        Assert.isTrue(exception1);
 
        List<Incentive__c> invalidParentOnly = TestDataFactory.createIncentive(1);
        invalidParentOnly[0].parent_incentive__c = [SELECT Id FROM Incentive__c LIMIT 1].Id;
        Boolean exception2 = false;
        try { 
            insert invalidParentOnly; 
        } catch (Exception e) { 
            exception2 = true; 
        }
        Assert.isTrue(exception2);
    }
 
    @IsTest
    static void testChildDuplicateInsertDatabase() {
        Incentive__c parent = [SELECT Id FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        List<Incentive__c> newChild = TestDataFactory.createIncentive(1);
        newChild[0].parent_incentive__c = parent.Id;
        newChild[0].month__c = 'April';
        Boolean exceptionThrown = false;
        try { 
            insert newChild; 
        } catch (Exception e) { 
            exceptionThrown = true; 
        }
        Assert.isTrue(exceptionThrown);
    }
 
    @IsTest
    static void testParentUpdateAmountCascades() {
        Incentive__c parent = [SELECT Id, amount__c FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        parent.amount__c = 2400;
        Test.startTest();
        update parent;
        Test.stopTest();
        List<Incentive__c> children = [SELECT amount__c FROM Incentive__c WHERE parent_incentive__c = :parent.Id];
        Assert.areEqual(200, children[0].amount__c);
    }
 
    @IsTest
    static void testParentUpdateAmountToNullCascades() {
        Incentive__c parent = [SELECT Id, amount__c FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        parent.amount__c = null;
        Test.startTest();
        update parent;
        Test.stopTest();
        List<Incentive__c> children = [SELECT amount__c FROM Incentive__c WHERE parent_incentive__c = :parent.Id];
        Assert.areEqual(0, children[0].amount__c);
    }
 
    @IsTest
    static void testParentUpdateMonthFails() {
        Incentive__c parent = [SELECT Id FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        parent.month__c = 'January';
        Boolean exceptionThrown = false;
        try { 
            update parent; 
        } catch (Exception e) { 
            exceptionThrown = true; 
        }
        Assert.isTrue(exceptionThrown);
    }
 
    @IsTest
    static void testChildUpdateAmountFails() {
        Incentive__c child = [SELECT Id, amount__c FROM Incentive__c WHERE parent_incentive__c != null LIMIT 1];
        child.amount__c = 500;
        Boolean exceptionThrown = false;
        try { 
            update child; 
        } catch (Exception e) { 
            exceptionThrown = true; 
        }
        Assert.isTrue(exceptionThrown);
    }
 
    @IsTest
    static void testChildUpdateMonthValid() {
        Incentive__c parent = [SELECT Id FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        List<Incentive__c> children = [SELECT Id, month__c FROM Incentive__c WHERE parent_incentive__c = :parent.Id];
        delete children[0];
        Incentive__c childToUpdate = children[1];
        childToUpdate.month__c = children[0].month__c;
        Test.startTest();
        update childToUpdate;
        Test.stopTest();
        Incentive__c updatedChild = [SELECT month__c FROM Incentive__c WHERE Id = :childToUpdate.Id];
        Assert.areEqual(children[0].month__c, updatedChild.month__c);
    }
 
    @IsTest
    static void testChildUpdateMonthDuplicateFails() {
        Incentive__c parent = [SELECT Id FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        List<Incentive__c> children = [SELECT Id, month__c FROM Incentive__c WHERE parent_incentive__c = :parent.Id LIMIT 2];
        children[0].month__c = children[1].month__c;
        Boolean exceptionThrown = false;
        try { 
            update children[0]; 
        } catch (Exception e) { 
            exceptionThrown = true; 
        }
        Assert.isTrue(exceptionThrown);
    }
 
    @IsTest
    static void testParentDeleteCascadesToChildren() {
        Incentive__c parent = [SELECT Id FROM Incentive__c WHERE parent_incentive__c = null LIMIT 1];
        Test.startTest();
        delete parent;
        Test.stopTest();
        List<Incentive__c> remainingChildren = [SELECT Id FROM Incentive__c WHERE parent_incentive__c = :parent.Id];
        Assert.areEqual(0, remainingChildren.size());
    }
}