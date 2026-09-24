@IsTest
private class Project2TaskHelperTest {

    @TestSetup
    static void setupTestData() {
        List<Project2__c> projects = new List<Project2__c>();
        for(Integer i = 0; i < 200; i++) {
            projects.add(new Project2__c(Name = 'Bulk Project ' + i));
        }
        projects.add(new Project2__c(Name = 'Project Alpha'));
        projects.add(new Project2__c(Name = 'Project Gamma'));
        insert projects;
    }

    @IsTest
    static void testGetCompletedCount_MixedStatuses() {
        List<Project_Task__c> tasks = new List<Project_Task__c>{
            new Project_Task__c(Status__c = 'Completed'),
            new Project_Task__c(Status__c = 'Completed'),
            new Project_Task__c(Status__c = 'In Progress'),
            new Project_Task__c(Status__c = 'Not Started')
        };
        Assert.areEqual(2, Project2TaskHelper.getCompletedCount(tasks), 'Should count only Completed tasks');
    }

    @IsTest
    static void testGetCompletedCount_EmptyList() {
        Assert.areEqual(0, Project2TaskHelper.getCompletedCount(new List<Project_Task__c>()), 'Empty list should return 0');
    }

    @IsTest
    static void testGetCompletedCount_NoneCompleted() {
        List<Project_Task__c> tasks = new List<Project_Task__c>{
            new Project_Task__c(Status__c = 'Not Started'),
            new Project_Task__c(Status__c = 'In Progress')
        };
        Assert.areEqual(0, Project2TaskHelper.getCompletedCount(tasks), 'Should return 0 when none are completed');
    }

    @IsTest
    static void testGetCompletedCount_AllCompleted() {
        List<Project_Task__c> tasks = new List<Project_Task__c>{
            new Project_Task__c(Status__c = 'Completed'),
            new Project_Task__c(Status__c = 'Completed')
        };
        Assert.areEqual(2, Project2TaskHelper.getCompletedCount(tasks), 'Should return total when all are completed');
    }

    @IsTest
    static void testSingleInsertSuccess() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        insert new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');

        Project2__c updatedProj = [SELECT Total_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(1, updatedProj.Total_Tasks__c, 'Total_Tasks__c should be 1 after inserting one task');
    }

    @IsTest
    static void testInsertCompletedTaskFails() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Completed');

        Boolean exceptionThrown = false;
        try {
            insert task;
        } catch(Exception e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('New Task cannot be marked as "Completed" on Insertion'),
                'Unexpected error message: ' + e.getMessage()
            );
        }
        Assert.isTrue(exceptionThrown, 'Inserting a Completed task should throw an exception');
    }

    @IsTest
    static void testInsertRevertsCompletedSuffix() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task1 = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert task1;
        update new Project_Task__c(Id = task1.Id, Status__c = 'Completed');

        Project2__c afterComplete = [SELECT Name FROM Project2__c WHERE Id = :proj.Id];
        Assert.isTrue(afterComplete.Name.endsWith(' - Completed'), 'Setup: project should have suffix before second insert');

        insert new Project_Task__c(Name = 'Task 2', Project_Name__c = proj.Id, Status__c = 'Not Started');

        Project2__c updatedProj = [SELECT Name, Total_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.isFalse(updatedProj.Name.endsWith(' - Completed'), 'Inserting a new task should remove - Completed suffix');
        Assert.areEqual(2, updatedProj.Total_Tasks__c, 'Total_Tasks__c should reflect both tasks');
    }

    @IsTest
    static void testBulkInsertSuccess() {
        List<Project2__c> projects = [SELECT Id FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        List<Project_Task__c> tasks = new List<Project_Task__c>();
        for(Project2__c proj : projects) {
            tasks.add(new Project_Task__c(Name = 'Bulk Task', Project_Name__c = proj.Id, Status__c = 'Not Started'));
        }
        Test.startTest();
        insert tasks;
        Test.stopTest();

        List<Project2__c> updatedProjects = [SELECT Total_Tasks__c FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        for(Project2__c proj : updatedProjects) {
            Assert.areEqual(1, proj.Total_Tasks__c, 'Each bulk project should have Total_Tasks__c = 1');
        }
    }

    @IsTest
    static void testSingleUpdateToCompleted() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert task;

        update new Project_Task__c(Id = task.Id, Status__c = 'Completed');

        Project2__c updatedProj = [SELECT Name, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(1, updatedProj.Completed_Tasks__c, 'Completed_Tasks__c should be 1');
        Assert.isTrue(updatedProj.Name.endsWith(' - Completed'), 'Project name should end with - Completed when all tasks are done');
    }

    @IsTest
    static void testUpdateRevertStatusFromCompleted() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert task;
        update new Project_Task__c(Id = task.Id, Status__c = 'Completed');
        update new Project_Task__c(Id = task.Id, Status__c = 'In Progress');

        Project2__c updatedProj = [SELECT Name, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(0, updatedProj.Completed_Tasks__c, 'Completed_Tasks__c should be 0 after reverting');
        Assert.isFalse(updatedProj.Name.endsWith(' - Completed'), 'Suffix should be removed after reverting status');
    }

    @IsTest
    static void testUpdateNoStatusChange_CountsUnaffected() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert task;

        Project2__c afterInsert = [SELECT Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Decimal completedBefore = afterInsert.Completed_Tasks__c;

        update new Project_Task__c(Id = task.Id, Name = 'Task 1 Updated');

        Project2__c afterUpdate = [SELECT Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(completedBefore, afterUpdate.Completed_Tasks__c, 'Non-status update should not change Completed_Tasks__c');
    }

    @IsTest
    static void testUpdatePartialCompletion_NoSuffixAdded() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task1 = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        Project_Task__c task2 = new Project_Task__c(Name = 'Task 2', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert new List<Project_Task__c>{ task1, task2 };

        List<Project_Task__c> inserted = [SELECT Id FROM Project_Task__c WHERE Project_Name__c = :proj.Id];
        update new Project_Task__c(Id = inserted[0].Id, Status__c = 'Completed');

        Project2__c updatedProj = [SELECT Name, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(1, updatedProj.Completed_Tasks__c, 'Only 1 of 2 tasks completed');
        Assert.isFalse(updatedProj.Name.endsWith(' - Completed'), 'Suffix should not be added when not all tasks are completed');
    }

    @IsTest
    static void testBulkUpdateCompleteAndRevert() {
        List<Project2__c> projects = [SELECT Id FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        List<Project_Task__c> tasks = new List<Project_Task__c>();
        for(Project2__c proj : projects) {
            tasks.add(new Project_Task__c(Name = 'Bulk Task', Project_Name__c = proj.Id, Status__c = 'Not Started'));
        }
        insert tasks;

        List<Project_Task__c> tasksToComplete = new List<Project_Task__c>();
        for(Project_Task__c t : tasks) {
            tasksToComplete.add(new Project_Task__c(Id = t.Id, Status__c = 'Completed'));
        }
        Test.startTest();
        update tasksToComplete;
        Test.stopTest();

        List<Project2__c> completedProjects = [SELECT Name, Completed_Tasks__c FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        for(Project2__c proj : completedProjects) {
            Assert.areEqual(1, proj.Completed_Tasks__c, 'Completed_Tasks__c should be 1');
            Assert.isTrue(proj.Name.endsWith(' - Completed'), 'All bulk projects should have - Completed suffix');
        }

        List<Project_Task__c> tasksToRevert = new List<Project_Task__c>();
        for(Project_Task__c t : tasks) {
            tasksToRevert.add(new Project_Task__c(Id = t.Id, Status__c = 'In Progress'));
        }
        update tasksToRevert;

        List<Project2__c> revertedProjects = [SELECT Name, Completed_Tasks__c FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        for(Project2__c proj : revertedProjects) {
            Assert.areEqual(0, proj.Completed_Tasks__c, 'Completed_Tasks__c should be 0 after reverting');
            Assert.isFalse(proj.Name.endsWith(' - Completed'), '- Completed suffix should be removed after reverting');
        }
    }

    @IsTest
    static void testSingleDelete_TotalTasksDecremented() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task1 = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        Project_Task__c task2 = new Project_Task__c(Name = 'Task 2', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert new List<Project_Task__c>{ task1, task2 };

        delete task1;

        Project2__c updatedProj = [SELECT Total_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(1, updatedProj.Total_Tasks__c, 'Total_Tasks__c should decrement after delete');
    }

    @IsTest
    static void testDeleteLastTask_RemovesCompletedSuffix() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert task;
        update new Project_Task__c(Id = task.Id, Status__c = 'Completed');

        Project2__c afterComplete = [SELECT Name FROM Project2__c WHERE Id = :proj.Id];
        Assert.isTrue(afterComplete.Name.endsWith(' - Completed'), 'Setup: project should have suffix before delete');

        delete task;

        Project2__c updatedProj = [SELECT Name, Total_Tasks__c, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(0, updatedProj.Total_Tasks__c, 'Total_Tasks__c should be 0');
        Assert.areEqual(0, updatedProj.Completed_Tasks__c, 'Completed_Tasks__c should be 0');
        Assert.isFalse(updatedProj.Name.endsWith(' - Completed'), 'Suffix must be removed when last task is deleted');
    }

    @IsTest
    static void testDeleteNonCompletedTask_AllRemainingComplete_AddsSuffix() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task1 = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        Project_Task__c task2 = new Project_Task__c(Name = 'Task 2', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert new List<Project_Task__c>{ task1, task2 };
        update new Project_Task__c(Id = task1.Id, Status__c = 'Completed');

        delete task2;

        Project2__c updatedProj = [SELECT Name, Total_Tasks__c, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(1, updatedProj.Total_Tasks__c, 'One task should remain');
        Assert.areEqual(1, updatedProj.Completed_Tasks__c, 'Remaining task is completed');
        Assert.isTrue(updatedProj.Name.endsWith(' - Completed'), 'Suffix should be added when all remaining tasks are completed');
    }

    @IsTest
    static void testDeleteCompletedTask_RemainingNotAllComplete_RemovesSuffix() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Gamma' LIMIT 1];
        Project_Task__c task1 = new Project_Task__c(Name = 'T1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        Project_Task__c task2 = new Project_Task__c(Name = 'T2', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert new List<Project_Task__c>{ task1, task2 };
        update new List<Project_Task__c>{
            new Project_Task__c(Id = task1.Id, Status__c = 'Completed'),
            new Project_Task__c(Id = task2.Id, Status__c = 'Completed')
        };

        Project_Task__c task3 = new Project_Task__c(Name = 'T3', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert task3;

        delete task1;

        Project2__c updatedProj = [SELECT Name, Total_Tasks__c, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(2, updatedProj.Total_Tasks__c, 'Two tasks should remain');
        Assert.areEqual(1, updatedProj.Completed_Tasks__c, 'Only task2 is completed');
        Assert.isFalse(updatedProj.Name.endsWith(' - Completed'), 'Suffix should be removed when remaining tasks are not all completed');
    }

    @IsTest
    static void testBulkDelete() {
        List<Project2__c> projects = [SELECT Id FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        List<Project_Task__c> tasks = new List<Project_Task__c>();
        for(Project2__c proj : projects) {
            tasks.add(new Project_Task__c(Name = 'Bulk Task', Project_Name__c = proj.Id, Status__c = 'Not Started'));
        }
        insert tasks;

        Test.startTest();
        delete tasks;
        Test.stopTest();

        List<Project2__c> updatedProjects = [SELECT Total_Tasks__c FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        for(Project2__c proj : updatedProjects) {
            Assert.areEqual(0, proj.Total_Tasks__c, 'Total_Tasks__c should be 0 after bulk delete');
        }
    }

    @IsTest
    static void testUndelete_RestoresTotalTasks() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert task;
        delete task;

        Project2__c afterDelete = [SELECT Total_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(0, afterDelete.Total_Tasks__c, 'Setup: Total_Tasks__c should be 0 after delete');

        Test.startTest();
        undelete task;
        Test.stopTest();

        Project2__c afterUndelete = [SELECT Total_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(1, afterUndelete.Total_Tasks__c, 'Total_Tasks__c should be restored after undelete');
    }

    @IsTest
    static void testUndelete_AllTasksCompleted_SuffixAdded() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task1 = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        Project_Task__c task2 = new Project_Task__c(Name = 'Task 2', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert new List<Project_Task__c>{ task1, task2 };
        update new List<Project_Task__c>{
            new Project_Task__c(Id = task1.Id, Status__c = 'Completed'),
            new Project_Task__c(Id = task2.Id, Status__c = 'Completed')
        };
        delete task2;

        Project2__c afterDelete = [SELECT Name FROM Project2__c WHERE Id = :proj.Id];
        Assert.isTrue(afterDelete.Name.endsWith(' - Completed'), 'Setup: suffix should exist with only task1 remaining (completed)');

        Test.startTest();
        undelete task2;
        Test.stopTest();

        Project2__c afterUndelete = [SELECT Name, Total_Tasks__c, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(2, afterUndelete.Total_Tasks__c, 'Both tasks restored');
        Assert.areEqual(2, afterUndelete.Completed_Tasks__c, 'Both tasks are completed');
        Assert.isTrue(afterUndelete.Name.endsWith(' - Completed'), 'Suffix should remain when all tasks are completed after undelete');
    }

    @IsTest
    static void testUndelete_NotAllCompleted_SuffixRemoved() {
        Project2__c proj = [SELECT Id FROM Project2__c WHERE Name = 'Project Alpha' LIMIT 1];
        Project_Task__c task1 = new Project_Task__c(Name = 'Task 1', Project_Name__c = proj.Id, Status__c = 'Not Started');
        Project_Task__c task2 = new Project_Task__c(Name = 'Task 2', Project_Name__c = proj.Id, Status__c = 'Not Started');
        insert new List<Project_Task__c>{ task1, task2 };

        update new Project_Task__c(Id = task1.Id, Status__c = 'Completed');
        delete task2;

        Project2__c afterDelete = [SELECT Name FROM Project2__c WHERE Id = :proj.Id];
        Assert.isTrue(afterDelete.Name.endsWith(' - Completed'), 'Setup: project should be marked completed');
        
        Test.startTest();
        undelete task2;
        Test.stopTest();
        
        Project2__c afterUndelete = [SELECT Name, Total_Tasks__c, Completed_Tasks__c FROM Project2__c WHERE Id = :proj.Id];
        Assert.areEqual(2, afterUndelete.Total_Tasks__c, 'Both tasks restored');
        Assert.areEqual(1, afterUndelete.Completed_Tasks__c, 'Only task1 is completed');
        Assert.isFalse(afterUndelete.Name.endsWith(' - Completed'), 'Suffix should be removed when not all tasks are completed after undelete');
    }

    @IsTest
    static void testBulkUndelete() {
        List<Project2__c> projects = [SELECT Id FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        List<Project_Task__c> tasks = new List<Project_Task__c>();
        for(Project2__c proj : projects) {
            tasks.add(new Project_Task__c(Name = 'Bulk Task', Project_Name__c = proj.Id, Status__c = 'Not Started'));
        }
        insert tasks;
        delete tasks;

        Test.startTest();
        undelete tasks;
        Test.stopTest();

        List<Project2__c> restoredProjects = [SELECT Total_Tasks__c FROM Project2__c WHERE Name LIKE 'Bulk Project%'];
        for(Project2__c proj : restoredProjects) {
            Assert.areEqual(1, proj.Total_Tasks__c, 'Total_Tasks__c should be restored after bulk undelete');
        }
    }
}