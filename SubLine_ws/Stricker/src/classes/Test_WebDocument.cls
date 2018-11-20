@isTest
public class Test_WebDocument {
    static testmethod void testWebDocument() {
        
        TestUtilities.customSettings();
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Encomendas_canceladas__c = false;
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.RecordTypeId = [SELECT id from RecordType where DeveloperName ='Folha_de_Obra' and SObjectType = 'Opportunity'].Id;
		opp.CloseDate = system.today();
        opp.Name = 'Opp Teste';
        opp.StageName = 'Aberto';
        opp.CurrencyIsoCode = 'EUR';
        opp.Nweb__c = '1';
        insert opp;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(opp);
        
        c_WebDocument ctrl = new c_WebDocument(stdCtrl);
        ctrl.RedirectOpp();
    }
}