@isTest
public class test_SincronizarDossier {
    @isTest static void test_SincronizarDossier() {
        Test.startTest();
        
        Perfil_Integracao__c p = new Perfil_Integracao__c();
        p.Name = 'Integrator';
        p.Endpoint__c = 'http://148.63.246.73:5006/SalesStricker/clientStricker.asmx';
        insert p;
        
        Perfil_Integracao__c p1 = new Perfil_Integracao__c();
        p1.Name = 'WSDL_Contactos';
        p1.Endpoint__c = 'http://148.63.246.73:5006/SalesStricker/ContactosPHC.asmx';
        insert p1;
        
        Perfil_Integracao__c p2 = new Perfil_Integracao__c();
        p2.Name = 'WSDL_Viewer';
        p2.Endpoint__c = 'http://148.63.246.73:5006/SalesStricker/ViewerPHC.asmx';
        insert p2;
        
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
        
        Product2 prod = new Product2();
        prod.Name = 'Test Prod';
        prod.Cor__c = '00;01';
        prod.ProductCode = '81000';
        prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        insert prod;
        
        Opportunity opp1 = new Opportunity();
        opp1.AccountId = acc.Id;
        opp1.RecordTypeId = [SELECT id from RecordType where DeveloperName ='Folha_de_Obra' and SObjectType = 'Opportunity'].Id;
        opp1.CloseDate = system.today();
        opp1.Name = 'Opp Teste';
        opp1.StageName = 'Aberto';
        opp1.CurrencyIsoCode = 'EUR';
        opp1.Referencia_PHC__c = null;
        opp1.Email_para_envio_de_maquete__c = 'test@test.pt';
        insert opp1;
        
        opp1.Pricebook2Id = Test.getStandardPricebookId();
        update opp1;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp1.Id;
        oli.PricebookEntryId = [Select Id From PricebookEntry Where Product2.Name = 'Test Prod' and CurrencyIsoCode = 'EUR'].Id;
        oli.Quantity = 100;
        oli.UnitPrice = 1;
        oli.Preco_unitario__c = 1;
        oli.Preco_aplicado__c = 'Quantidade';
        insert oli;        
        
        ApexPages.StandardController std = new ApexPages.StandardController(opp1);
        c_SincronizarDossier controller = new c_SincronizarDossier(std);
        controller.callSync();
        
        opp1.Referencia_PHC__c = '1';
        opp1.Stamp__c = '123';
        update opp1;
        
        ApexPages.StandardController std2 = new ApexPages.StandardController(opp1);
        c_SincronizarDossier controller2 = new c_SincronizarDossier(std2);
        controller2.callSync();
        
        Test.stopTest();
    }
}