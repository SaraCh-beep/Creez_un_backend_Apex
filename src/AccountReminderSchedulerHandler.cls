/**
 * Handler du scheduler de rappel des comptes.
 *
 * Cette classe sépare la logique de lancement du batch
 * de la classe schedulable afin de respecter les bonnes pratiques Apex.
 */
public with sharing class AccountReminderSchedulerHandler {

    /**
     * Lance le batch AccountReminderBatch avec une taille de lot de 200 enregistrements.
     */
    public static void launchAccountReminderBatch() {
        Database.executeBatch(new AccountReminderBatch(), 200);
    }
}