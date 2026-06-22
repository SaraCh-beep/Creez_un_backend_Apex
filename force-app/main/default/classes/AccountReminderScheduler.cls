/**
 * Scheduler Apex utilisé pour lancer le batch de rappel des comptes.
 * 
 * La planification n'est pas définie dans le code.
 * Elle est configurée depuis Salesforce dans Apex Jobs / Schedule Apex.
 */
public with sharing class AccountReminderScheduler implements Schedulable {

    /**
     * Méthode exécutée automatiquement par Salesforce selon la planification configurée.
     */
    public void execute(SchedulableContext context) {
        AccountReminderSchedulerHandler.launchAccountReminderBatch();
    }
}