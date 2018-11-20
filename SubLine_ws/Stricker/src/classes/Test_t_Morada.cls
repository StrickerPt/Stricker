@isTest
public class Test_t_Morada {

    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
		
        Morada_de_entrega__c newMorada = new Morada_de_entrega__c();
        newMorada.Conta__c = result.acc.Id;

        insert newMorada;
        checkRecursive.runMoradaCliente = true;
        update newMorada;
        
        checkRecursive.runMoradaCliente = true;
        delete newMorada;
    }
}