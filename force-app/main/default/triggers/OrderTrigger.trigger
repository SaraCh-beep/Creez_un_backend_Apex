/**
 * Trigger sur l'objet Order.
 *
 * RG-01 :
 * Empêche l'activation d'une commande lorsqu'aucun produit
 * n'est associé à celle-ci.
 *
 * RG-02 :
 * - Coche automatiquement le champ Account_Active__c lorsqu'une
 *   commande est créée sur un compte.
 * - Décoche automatiquement le champ Account_Active__c lorsque
 *   toutes les commandes du compte ont été supprimées.
 */
trigger OrderTrigger on Order (before update, after insert, after delete) {

    /**
     * RG-01
     * Avant la mise à jour d'une commande, vérifie que
     * l'utilisateur ne tente pas de passer le statut
     * de Draft à Activated sans produit associé.
     */
    if (Trigger.isBefore && Trigger.isUpdate) {
        OrderService.preventActivationWithoutProducts(
            Trigger.new,
            Trigger.oldMap
        );
    }

    /**
     * RG-02
     * Après la création d'une commande, active automatiquement
     * le compte associé en cochant le champ Account_Active__c.
     */
    if (Trigger.isAfter && Trigger.isInsert) {
        OrderService.activateAccountsAfterOrderCreation(
            Trigger.new
        );
    }

    /**
     * RG-02
     * Après la suppression d'une commande, vérifie s'il reste
     * d'autres commandes sur le compte.
     * Si aucune commande ne subsiste, le compte est désactivé.
     */
    if (Trigger.isAfter && Trigger.isDelete) {
        OrderService.updateAccountActiveAfterOrderDeletion(
            Trigger.old
        );
    }
}