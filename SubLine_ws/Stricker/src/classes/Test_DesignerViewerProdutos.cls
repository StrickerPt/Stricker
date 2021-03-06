@isTest
public class Test_DesignerViewerProdutos {
    
    static testmethod void test1(){
        test.startTest();
        
        TestUtilities.customSettings();
        createProds();

        ResultCreateOpp result = createOpp();
        for(Product2 p : [Select id, REcordType.Name from Product2 ]){
            system.debug(p.REcordType.Name);
        }
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_DesignerViewerProdutos myCtrl = new c_DesignerViewerProdutos(ctrl);
        
        
        test.stopTest();
    }
    
    public static void createProds(){
        List<Product2> newProds = new List<Product2>();
        Product2 prodGen = new Product2();
        prodGen.Name = 'Genérico';
        prodGen.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(prodGen);
        
        Product2 prod = new Product2();
        prod.Name = 'Test Prod';
        prod.Cor__c = '00;01';
        prod.ProductCode = '81000';
        prod.Peso_caixa__c = '123';
        prod.Caixa_exterior_unidades__c = '1';
        prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(prod);
        
        Product2 custom = new Product2();
        custom.Name = 'Test Custom';
        custom.Referencia_relacionada__c = '81000';
        custom.Componente_da_impressao__c = 'Frasco';
        custom.Cores_de_customizacao__c = '2';
        custom.Peso_caixa__c = '123';
        custom.Caixa_exterior_unidades__c = '1';
        custom.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Customização').getRecordTypeId();
        newProds.add(custom);
        
        insert newProds;
    }
    
    public static ResultCreateOpp createOpp(){
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
        insert opp;
        
        opp.Pricebook2Id = Test.getStandardPricebookId();
        update opp;
        
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId = opp.Id;
        oli.PricebookEntryId = [Select Id From PricebookEntry Where Product2.Name = 'Test Prod' and CurrencyIsoCode = 'EUR'].Id;
        oli.Quantity = 100;
       	oli.UnitPrice = 1;
        oli.Preco_unitario__c = 1;
        oli.Preco_aplicado__c = 'Quantidade';
        insert oli;
        
        OpportunityLineItem oli2 = new OpportunityLineItem();
        oli2.OpportunityId = opp.Id;
        oli2.PricebookEntryId = [Select Id From PricebookEntry Where Product2.Referencia_relacionada__c = '81000' and CurrencyIsoCode = 'EUR'].Id;
        oli2.Quantity = 100;
       	oli2.UnitPrice = 1;
        oli2.Referencia_Relacionada__c = oli.Id;
        oli2.Preco_aplicado__c = 'Quantidade';        
        insert oli2;
        
        Morada_de_entrega__c morada = new Morada_de_entrega__c(Morada_de_entrega__c='Morada teste',Conta__c=acc.Id,Localidade__c='Localidade teste',Codigo_postal__c='2100-000',Pais__c='PT',Telefone_logistico__c='210035910');
        insert morada;
        
        Expedicao__c exp = new Expedicao__c(Peso_da_expedicao__c=2,Volume_da_expedicao__c=2,Morada_de_entrega__c=morada.Id,Transportadora__c='Transportadora teste',Observacoes_documento__c='Observações documento teste',Dossier__c=opp.Id);
        insert exp;
        
        ResultCreateOpp result = new ResultCreateOpp();
        result.opp = opp;
        result.exp = exp;
        
        return result;
    }

    class ResultCreateOpp{
        public Opportunity opp{get;set;}
        public Expedicao__c exp{get;set;}
    }
}