# Creez un backend Apex - iDEM Connect

Projet Salesforce Apex réalisé pour iDEM Connect.

## Fonctionnalités

- RG-01 : empêcher l'activation d'un Order sans produit associé.
- RG-02 : décocher Account_Active__c lorsqu'un compte n'a plus aucun Order.
- RG-03 : créer automatiquement une tâche Call pour les comptes sans Order.

## Contenu du dépôt

- OrderTrigger
- OrderService
- AccountReminderBatch
- AccountReminderScheduler
- AccountReminderSchedulerHandler
- OrderServiceTest
- AccountReminderBatchTest

## Couverture de code

Couverture globale obtenue : 93 %.