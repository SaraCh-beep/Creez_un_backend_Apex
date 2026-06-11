/**
 * Classe de test du batch AccountReminderBatch.
 *
 * Cette classe valide les règles métier de la RG-03 :
 * - Création d'une tâche Call pour les comptes sans Order.
 * - Absence de création de doublons si une tâche Call existe déjà.
 * - Exécution correcte du scheduler.
 */
@IsTest
private class AccountReminderBatchTest {

    /**
     * Vérifie qu'une tâche Call est créée
     * lorsqu'un compte ne possède aucun Order associé.
     */
    @IsTest
    static void testCreateCallTaskForAccountWithoutOrder() {

        Account acc = new Account(
            Name = 'Account Without Order'
        );
        insert acc;

        Test.startTest();

        Database.executeBatch(
            new AccountReminderBatch(),
            200
        );

        Test.stopTest();

        List<Task> tasks = [
            SELECT Id, Subject
            FROM Task
            WHERE WhatId = :acc.Id
        ];

        // Vérifie qu'une seule tâche a été créée.
        System.assertEquals(
            1,
            tasks.size()
        );

        // Vérifie que la tâche créée est de type Call.
        System.assertEquals(
            'Call',
            tasks[0].Subject
        );
    }

    /**
     * Vérifie qu'aucune tâche supplémentaire n'est créée
     * lorsqu'une tâche Call existe déjà sur le compte.
     */
    @IsTest
    static void testDoNotCreateDuplicateCallTask() {

        Account acc = new Account(
            Name = 'Account With Existing Task'
        );
        insert acc;

        Task existingTask = new Task(
            Subject = 'Call',
            Status = 'Not Started',
            Priority = 'Normal',
            WhatId = acc.Id,
            OwnerId = UserInfo.getUserId(),
            ActivityDate = Date.today()
        );

        insert existingTask;

        Test.startTest();

        Database.executeBatch(
            new AccountReminderBatch(),
            200
        );

        Test.stopTest();

        Integer taskCount = [
            SELECT COUNT()
            FROM Task
            WHERE WhatId = :acc.Id
            AND Subject = 'Call'
        ];

        // Vérifie qu'une seule tâche Call existe toujours.
        System.assertEquals(
            1,
            taskCount
        );
    }

    /**
     * Vérifie que le scheduler peut être planifié
     * et qu'un Job Salesforce est correctement créé.
     */
    @IsTest
    static void testSchedulerExecution() {

        Test.startTest();

        String jobId = System.schedule(
            'Test Scheduler',
            '0 0 8 ? * MON#1 *',
            new AccountReminderScheduler()
        );

        Test.stopTest();

        // Vérifie qu'un identifiant de job a été généré.
        System.assertNotEquals(
            null,
            jobId
        );
    }
}