@isTest
public class Test_ConvertLead {
    static testmethod void Test_ConvertLead() {
        TestUtilities.customSettings();
        
        Lead newLead = new Lead(FirstName = 'Teste', LastName='Name', Company='Companhia');
        insert newLead;
        
        newLead.Aprovado__c = true;
        update newLead;
        
        IntegratorClientes.createCustomer(new Set<Id>{newLead.Id});
    }
}