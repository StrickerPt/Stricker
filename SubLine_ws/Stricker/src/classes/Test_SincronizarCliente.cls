@isTest
public class Test_SincronizarCliente {

    static testmethod void test1(){
        
        TestUtilities.customSettings();
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Numero_de_cliente__c = '57981';
        acc.Encomendas_canceladas__c = false;
        acc.Portes__c = '';
        insert acc;
        
        Test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(acc);
        c_SincronizarCliente c = new c_SincronizarCliente(ctrl);
        
        c.callSync();
        
        c.acc.Numero_de_cliente__c = '0';
        c.callSync();
        
        Test.stopTest();
    }
}