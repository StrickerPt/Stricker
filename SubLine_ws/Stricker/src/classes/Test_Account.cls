@isTest
public class Test_Account {
    
    static testmethod void Account() {
        test.startTest();
        
        Objectivo_de_faturacao__c obj = new  Objectivo_de_faturacao__c();
        obj.Ano__c = System.today().year();
        obj.Pais__c = 'PT';
        insert obj;
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.Diretor_comerial__c = UserInfo.getUserId();
        acc.OwnerId = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Encomendas_canceladas__c = false;
        acc.Prefixo_pais_de_contribuinte__c = 'PT';
        insert acc;
        
        test.stopTest();
    }
    
    static testmethod void Account2() {
        test.startTest();
        
        Objectivo_de_faturacao__c obj = new  Objectivo_de_faturacao__c();
        obj.Ano__c = System.today().year();
        obj.Pais__c = 'PT';
        obj.Mercado__c = 'PT Porto';
        insert obj;
        
        Objectivo_de_faturacao__c obj2 = new  Objectivo_de_faturacao__c();
        obj2.Ano__c = System.today().year();
        obj2.Pais__c = 'PT';
        obj2.Mercado__c = 'PT Lisboa';
        insert obj2;
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Encomendas_canceladas__c = false;
        acc.Prefixo_pais_de_contribuinte__c = 'PT';
        acc.Mercado__c = 'PT Lisboa';
        insert acc;
        
        test.stopTest();
    }
    
    static testmethod void Account3() {
        test.startTest();
        
        Objectivo_de_faturacao__c obj = new  Objectivo_de_faturacao__c();
        obj.Ano__c = System.today().year();
        obj.Pais__c = null;
        insert obj;
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Encomendas_canceladas__c = false;
        acc.Prefixo_pais_de_contribuinte__c = 'PT';
        insert acc;
        
        test.stopTest();
    }
    @TestSetup
    public static void setup(){
        
        TestUtilities.customSettings();
    }
}