public with sharing class AccountReminderBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id, OwnerId
            FROM Account
            WHERE Id NOT IN (
                SELECT AccountId
                FROM Order
                WHERE AccountId != null
            )
        ]);
    }

    public void execute(Database.BatchableContext context, List<Account> scope) {
        Set<Id> accountIds = new Set<Id>();

        for (Account accountRecord : scope) {
            accountIds.add(accountRecord.Id);
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Set<Id> accountsWithCallTask = new Set<Id>();

        for (Task taskRecord : [
            SELECT WhatId
            FROM Task
            WHERE WhatId IN :accountIds
            AND Subject = 'Call'
        ]) {
            accountsWithCallTask.add(taskRecord.WhatId);
        }

        List<Task> tasksToInsert = new List<Task>();

        for (Account accountRecord : scope) {
            if (!accountsWithCallTask.contains(accountRecord.Id)) {
                tasksToInsert.add(new Task(
                    Subject = 'Call',
                    Status = 'Not Started',
                    Priority = 'Normal',
                    OwnerId = accountRecord.OwnerId,
                    WhatId = accountRecord.Id,
                    ActivityDate = Date.today().addDays(5),
                    IsReminderSet = true,
                    ReminderDateTime = System.now().addDays(5)
                ));
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    public void finish(Database.BatchableContext context) {
    }
}