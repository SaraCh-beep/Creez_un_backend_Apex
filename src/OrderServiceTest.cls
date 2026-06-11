/**
 * Classe de test de OrderService.
 *
 * Cette classe valide :
 * - RG-01 : blocage de l'activation d'un Order sans produit.
 * - RG-02 : mise à jour du champ Account_Active__c après suppression d'un Order.
 */
@IsTest
private class OrderServiceTest {

    /**
     * Crée les données communes utilisées par les tests :
     * - un compte actif ;
     * - un contrat lié au compte.
     */
    @TestSetup
    static void setupData() {

        Account acc = new Account(
            Name = 'Test Account',
            Account_Active__c = true
        );
        insert acc;

        Contract con = new Contract(
            AccountId = acc.Id,
            Status = 'Draft',
            StartDate = Date.today(),
            ContractTerm = 12
        );
        insert con;
    }

    /**
     * RG-02
     * Vérifie que le champ Account_Active__c est décoché
     * lorsque le dernier Order lié au compte est supprimé.
     */
    @IsTest
    static void testDeactivateAccountAfterOrderDeletion() {

        Account acc = [
            SELECT Id, Account_Active__c
            FROM Account
            LIMIT 1
        ];

        Contract con = [
            SELECT Id
            FROM Contract
            LIMIT 1
        ];

        Order ord = new Order(
            AccountId = acc.Id,
            ContractId = con.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert ord;

        Test.startTest();

        delete ord;

        Test.stopTest();

        Account updatedAcc = [
            SELECT Account_Active__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            false,
            updatedAcc.Account_Active__c
        );
    }

    /**
     * RG-02
     * Vérifie que le champ Account_Active__c reste coché
     * lorsqu'un compte possède encore au moins un Order après suppression.
     */
    @IsTest
    static void testKeepAccountActiveWhenAnotherOrderExists() {

        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        Contract con = [
            SELECT Id
            FROM Contract
            LIMIT 1
        ];

        Order ord1 = new Order(
            AccountId = acc.Id,
            ContractId = con.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );

        Order ord2 = new Order(
            AccountId = acc.Id,
            ContractId = con.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );

        insert new List<Order>{ord1, ord2};

        Test.startTest();

        delete ord1;

        Test.stopTest();

        Account updatedAcc = [
            SELECT Account_Active__c
            FROM Account
            WHERE Id = :acc.Id
        ];

        System.assertEquals(
            true,
            updatedAcc.Account_Active__c
        );
    }

    /**
     * RG-01
     * Vérifie qu'un Order sans OrderItem ne peut pas passer
     * du statut Draft au statut Activated.
     */
    @IsTest
    static void testBlockActivationWithoutProduct() {

        Account acc = [
            SELECT Id
            FROM Account
            LIMIT 1
        ];

        Contract con = [
            SELECT Id
            FROM Contract
            LIMIT 1
        ];

        Order ord = new Order(
            AccountId = acc.Id,
            ContractId = con.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert ord;

        Test.startTest();

        ord.Status = 'Activated';

        try {
            update ord;
            System.assert(false, 'La commande ne devait pas être activée sans produit.');
        } catch (DmlException e) {
            System.assert(
                e.getMessage().contains('Vous devez ajouter au moins un produit'),
                'Le message d’erreur attendu doit être affiché.'
            );
        }

        Test.stopTest();
    }
}