@isTest
public class Test_ViewerProdutosPesquisados {
    static testmethod void c_ProdutosPesquisados() {
        test.startTest();

        TestUtilities.customSettings();
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Numero_de_cliente__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Encomendas_canceladas__c = false;
        insert acc;
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(acc);
        c_ViewerProdutosPesquisados myCtrl = new c_ViewerProdutosPesquisados(ctrl);
        myCtrl.init();
        test.stopTest();
    }
}