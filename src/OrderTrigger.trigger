/**
 * Trigger sur l'objet Order.
 *
 * RG-01 : empêche l'activation d'une commande sans produit associé.
 * RG-02 : met à jour le champ Account_Active__c du compte après suppression d'une commande.
 */
trigger OrderTrigger on Order (before update, after delete) {

    // RG-01 : avant modification, vérifie le passage du statut Draft à Activated.
    if (Trigger.isBefore && Trigger.isUpdate) {
        OrderService.preventActivationWithoutProducts(
            Trigger.new,
            Trigger.oldMap
        );
    }

    // RG-02 : après suppression, vérifie s'il reste des commandes sur le compte.
    if (Trigger.isAfter && Trigger.isDelete) {
        OrderService.updateAccountActiveAfterOrderDeletion(
            Trigger.old
        );
    }
}