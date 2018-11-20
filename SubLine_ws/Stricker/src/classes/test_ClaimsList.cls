@isTest
public class test_ClaimsList {
    @isTest static void test_ClaimsList() {
        
        Test.startTest();
        
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
        insert acc;
        
        Token_site__c t = new Token_site__c();
        t.Numero_de_cliente__c = acc.Numero_de_cliente__c;
        t.Token__c = ''; 
        t.Ip__c = '';
        t.Endereco_de_retorno__c = '';
        t.Data_de_entrada__c = system.today() - 1;
        t.Data_de_validade__c= system.today() + 50;
        t.Duracao__c = 10;
        t.Validado__c = true;
        insert t;
        
      
        
        Test.setCurrentPageReference(new PageReference('Page.p_AddProduct')); 
        System.currentPageReference().getParameters().put('no', acc.Numero_de_cliente__c);
        System.currentPageReference().getParameters().put('validClient', 'true');
        
          c_ClaimsList c = new c_ClaimsList();
        c.checkPermaValidate();
        
        acc.Numero_de_cliente__c = null;
        update acc;
        c_ClaimsList c1 = new c_ClaimsList();
        
        Test.stopTest();
    }
}