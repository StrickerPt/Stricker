@isTest
public class Test_t_Opportunity {
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
        opp.Stamp__c = 'testStamp';
        insert opp;
        
        opp.StageName = 'Pedido de maquete';
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        update opp;
        
        opp.Designer__c = Opportunity.Designer__c.getDescribe().getPicklistValues().get(0).getValue();
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        update opp;
        
        opp.Estado_da_maquete__c = 'Em aprovação do cliente';
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        update opp;

        opp.Estado_da_maquete__c = 'Aprovada';
        opp.Em_falta__c = false;
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        update opp;
        
        opp.Estado_da_maquete__c = 'Suspenso';
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        update opp;
        
        opp.Estado_da_maquete__c = 'Por aceitar';
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        update opp;
    }
    //test Amostra
    testmethod static void test2(){
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
        opp.Estado_da_maquete__c = 'Aprovada';
        opp.Auxiliar_aprovacao_de_maquete__c = false;
        opp.Email_para_envio_de_maquete__c = 'test@test.pt';
        opp.Stamp__c = 'testStamp';
        opp.Amostra__c = true;
        opp.Destino_de_impressao__c = 'Normal';
        opp.Documento_de_destino__c = 'Factura TER';
        insert opp;
        
        opp.Pricebook2Id = Test.getStandardPricebookId();
        update opp;
        
        Product2 prod = new Product2();
        prod.ProductCode = 'NSAPTI';
        prod.Name = 'Test';
        insert prod;

        
        opp.Autorizada__c = 'TST';
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        update opp;
    }
    testmethod static void test3(){
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
        opp.Stamp__c = 'testStamp';
        insert opp;
        
        try{
            delete opp;
        }catch(Exception ex){}
    }
    
     testmethod static void test4(){
       TestUtilities.customSettings();
        TestUtilities.createProds();
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
        opp.Stamp__c = 'testStamp';
        insert opp;
        
        opp.Pricebook2Id = Test.getStandardPricebookId();
        update opp;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.PricebookEntryId = [Select Id From PricebookEntry Where ProductCode = '81000' And CurrencyIsoCode = 'EUR'].Id;
        oli.UnitPrice = 0;
        oli.Quantity = 1;
        checkRecursive.runOpportunityBeforeUpdate = true;
        checkRecursive.runOpportunityAfterUpdate = true;
        insert oli;
        
        
     }
}