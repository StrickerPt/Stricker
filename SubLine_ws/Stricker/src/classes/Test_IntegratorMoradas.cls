@isTest
public class Test_IntegratorMoradas {
    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Morada_de_entrega__c newMorada = new Morada_de_entrega__c();
        newMorada.Conta__c = result.acc.Id;
        newMorada.Stamp__c = '123';
        
        insert newMorada;
        
        IntegratorMoradas.moradaClienteUpsert(new Set<Id>{newMorada.Id});
        
        IntegratorMoradas.MoradaClienteDelete(JSON.serialize(new List<IntegratorMoradas.DeleteMoradaCliente>{new IntegratorMoradas.DeleteMoradaCliente(newMorada.Id, newMorada.Stamp__c)}));
    }
}