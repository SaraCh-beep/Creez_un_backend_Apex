/**
 * Handler du scheduler de rappel des comptes.
 * Cette classe centralise la logique lancée par le scheduler.
 */
public with sharing class AccountReminderSchedulerHandler {

    /**
     * Lance le batch de création des tâches de rappel.
     */
    public static void launchAccountReminderBatch() {
        Database.executeBatch(new AccountReminderBatch(), 200);
    }
}