/**
 * Classe de service contenant la logique métier liée aux commandes.
 *
 * Cette classe est appelée par OrderTrigger.
 * Elle gère :
 * - RG-01 : blocage de l'activation d'une commande sans produit.
 * - RG-02 : activation/désactivation du compte selon ses commandes.
 */
public with sharing class OrderService {

    public static final String ORDER_STATUS_DRAFT = 'Draft';
    public static final String ORDER_STATUS_ACTIVATED = 'Activated';

    /**
     * RG-01
     * Vérifie qu'une commande possède au moins un OrderItem avant son activation.
     *
     * Si une commande passe de Draft à Activated sans produit associé,
     * l'enregistrement est bloqué avec un message d'erreur.
     */
    public static void preventActivationWithoutProducts(
        List<Order> newOrders,
        Map<Id, Order> oldOrderMap
    ) {
        Set<Id> orderIdsToCheck = new Set<Id>();

        for (Order newOrder : newOrders) {
            Order oldOrder = oldOrderMap.get(newOrder.Id);

            if (
                oldOrder != null &&
                oldOrder.Status == ORDER_STATUS_DRAFT &&
                newOrder.Status == ORDER_STATUS_ACTIVATED
            ) {
                orderIdsToCheck.add(newOrder.Id);
            }
        }

        if (orderIdsToCheck.isEmpty()) {
            return;
        }

        Set<Id> ordersWithProducts = new Set<Id>();

        for (AggregateResult result : [
            SELECT OrderId orderId
            FROM OrderItem
            WHERE OrderId IN :orderIdsToCheck
            GROUP BY OrderId
        ]) {
            ordersWithProducts.add((Id) result.get('orderId'));
        }

        for (Order newOrder : newOrders) {
            if (
                orderIdsToCheck.contains(newOrder.Id) &&
                !ordersWithProducts.contains(newOrder.Id)
            ) {
                newOrder.addError(
                    'Vous devez ajouter au moins un produit avant d’activer cette commande.'
                );
            }
        }
    }

    /**
     * RG-02
     * Active automatiquement le compte lorsqu'une commande
     * est créée et rattachée à celui-ci.
     */
    public static void activateAccountsAfterOrderCreation(
        List<Order> newOrders
    ) {
        Set<Id> accountIds = new Set<Id>();

        for (Order newOrder : newOrders) {
            if (newOrder.AccountId != null) {
                accountIds.add(newOrder.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Account accountRecord : [
            SELECT Id, Account_Active__c
            FROM Account
            WHERE Id IN :accountIds
            AND Account_Active__c = false
        ]) {
            accountRecord.Account_Active__c = true;
            accountsToUpdate.add(accountRecord);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    /**
     * RG-02
     * Met à jour les comptes liés aux commandes supprimées.
     *
     * Si un compte n'a plus aucune commande après suppression,
     * le champ Account_Active__c est décoché.
     */
    public static void updateAccountActiveAfterOrderDeletion(
        List<Order> deletedOrders
    ) {
        Set<Id> accountIds = new Set<Id>();

        for (Order deletedOrder : deletedOrders) {
            if (deletedOrder.AccountId != null) {
                accountIds.add(deletedOrder.AccountId);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        Set<Id> accountsWithRemainingOrders = new Set<Id>();

        for (AggregateResult result : [
            SELECT AccountId accountId
            FROM Order
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ]) {
            accountsWithRemainingOrders.add((Id) result.get('accountId'));
        }

        List<Account> accountsToUpdate = new List<Account>();

        for (Account accountRecord : [
            SELECT Id, Account_Active__c
            FROM Account
            WHERE Id IN :accountIds
            AND Account_Active__c = true
        ]) {
            if (!accountsWithRemainingOrders.contains(accountRecord.Id)) {
                accountRecord.Account_Active__c = false;
                accountsToUpdate.add(accountRecord);
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}