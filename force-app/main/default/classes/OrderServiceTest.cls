@IsTest
private class OrderServiceTest {

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
    /**
     * RG-02
     * Vérifie qu'un compte est automatiquement activé
     * lorsqu'une commande est créée et rattachée à ce compte.
     */
    @IsTest
    static void testActivateAccountAfterOrderCreation() {

        Account acc = [
            SELECT Id, Account_Active__c
            FROM Account
            LIMIT 1
        ];

        acc.Account_Active__c = false;
        update acc;

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

        Test.startTest();

        insert ord;

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
}