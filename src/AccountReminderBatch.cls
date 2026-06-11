/**
 * Batch Apex de rappel des comptes.
 *
 * RG-03 :
 * Recherche les comptes sans commande associée et sans tâche Call existante.
 * Pour chaque compte concerné, une tâche de rappel est créée pour le propriétaire du compte.
 */
public with sharing class AccountReminderBatch implements Database.Batchable<SObject> {

    /**
 * Récupère les comptes qui n'ont aucun Order associé.
 */
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

    /**
 * Pour chaque lot de comptes, vérifie l'existence d'une tâche Call.
 * Si aucune tâche Call n'existe, crée une tâche de rappel.
 */
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

    /**
 * Méthode exécutée à la fin du batch.
 * Aucun traitement final n'est nécessaire pour ce projet.
 */
public void finish(Database.BatchableContext context) {
}
}