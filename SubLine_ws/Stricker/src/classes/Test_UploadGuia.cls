@isTest
public class Test_UploadGuia {

    testmethod static void test1(){
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
        opp.Estado_da_maquete__c = 'Por aceitar';
        opp.Auxiliar_aprovacao_de_maquete__c = false;
        opp.Email_para_envio_de_maquete__c = 'test@test.pt';
        insert opp;
        
        opp.Pricebook2Id = Test.getStandardPricebookId();
        update opp;
        
        Test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(opp);
        c_UploadGuia myCtrl = new c_UploadGuia(ctrl);
        myCtrl.blobFile = 'Teste Blob';
        myCtrl.fileName = 'Teste File';
        myCtrl.showBlob();
        Test.stopTest();
    }
}