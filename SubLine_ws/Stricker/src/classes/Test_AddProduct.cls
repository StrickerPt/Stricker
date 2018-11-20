@isTest
public class Test_AddProduct {
    
    static testMethod void test1(){
        test.startTest();
        
        createProds();
        TestUtilities.customSettings();
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Tabela_de_customizacoes__c = true;
        acc.Mercado_de_customizacoes__c = '3';
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
        oli.PricebookEntryId = [Select Id From PricebookEntry Where Product2.Name = 'Test Prod' And CurrencyIsoCode = :opp.CurrencyIsoCode].Id;
        oli.Quantity = 100;
       	oli.UnitPrice = 1;
        oli.Preco_unitario__c = 1;
        oli.Preco_aplicado__c = 'Quantidade';
        insert oli;
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(opp);
        c_AddProduct myCtrl = new c_AddProduct(ctrl);

        myCtrl.header = myctrl.produtos.get(oli.Id).item.clone();
        myCtrl.getColors();
        myCtrl.refreshTable();
        myCtrl.setCustom();
        myCtrl.getSize();
        
        myCtrl.tablePrice = 1;
        myCtrl.insertPriceByTable();
        
        myCtrl.header.Discount = 1;
        myCtrl.insertDiscount();
        
        myCtrl.header.Valor_de_tabela_de_precos__c = true;
        
        myCtrl.valueTabChange();
        myCtrl.valueTabChangeLine();
        myCtrl.addProduct();
        
        myCtrl.produtoGenerico = true;
        myCtrl.addProduct();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.cloneOLI();
        
        myCtrl.apagarAgrupadores();
        myCtrl.insertPrice();
        
        myCtrl.agrupamento.put(oli.Id, true);
        myCtrl.criarAgrupamento();

        myCtrl.idGroup = myCtrl.produtos.get(oli.Id).item.Agrupador_OLI__c;
        myCtrl.deleteAgrupador();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.priceByQuantityLine();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.priceByValueLine();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.priceByTablePriceLine();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.changeSKU();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.getColorsModal();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.createColorLines();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.createNewColorLines();
        
        myCtrl.blobFile = EncodingUtil.base64Encode(EncodingUtil.base64Decode('testString'));
        myCtrl.fileName = 'Test File';
        myCtrl.showBlob();
        
        myCtrl.getComponentMap();
        myCtrl.getTecnicaMap();
        myCtrl.getvalorTotal();
        
        myCtrl.save();
        
        Integrator.criaDossier(opp.Id);
        Integrator.actDossier(new Set<Id>{opp.Id});
        
        test.stopTest();
    }
    
    static testMethod void test2(){
        test.startTest();
        
        createProds();
        TestUtilities.customSettings();
        
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Tabela_de_customizacoes__c = true;
        acc.Mercado_de_customizacoes__c = '3';
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
        oli.PricebookEntryId = [Select Id From PricebookEntry Where Product2.Name = 'Test Prod' And CurrencyIsoCode = :opp.CurrencyIsoCode].Id;
        oli.Quantity = 100;
        oli.UnitPrice = 1;
        oli.Preco_unitario__c = 1;
        oli.Preco_aplicado__c = 'Quantidade';
        insert oli;
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(opp);
        c_AddProduct myCtrl = new c_AddProduct(ctrl);
        
        
        myCtrl.header = myctrl.produtos.get(oli.Id).item.clone();
        myCtrl.getStockHeader();
        
        myCtrl.addProduct();
        
        myCtrl.refreshCustomsHeader();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.setShow();
        
        myCtrl.idProduct = oli.Id;
        myctrl.getCustoms();
        
        system.debug(myCtrl.customs.get('Frasco'));
        system.debug(myCtrl.customs.get('Frasco'));
        myCtrl.typeCustom = 'Frasco';
        myctrl.idCustom = 'Laser';
        myctrl.nameCustom = null;
		myCtrl.addCustom();
        
        myCtrl.idProduct = oli.Id;
        myctrl.idCustom = myCtrl.customs.get('Frasco').get('Laser').get(null).Id;
        myCtrl.changePriceInCustom();
        
        myCtrl.typeCustom = oli.Id;
        myCtrl.idProduct = oli.Id;
        myctrl.idCustom = myCtrl.customs.get('Frasco').get('Laser').get(null).Id;
        myCtrl.valueChangeReps();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.cloneOLI();
        myCtrl.typeCustom = oli.Id;
        myCtrl.idProduct = oli.Id;
        myctrl.idCustom = myCtrl.customs.get('Frasco').get('Laser').get(null).Id;
        myCtrl.removeCustom();
        
        myCtrl.idProduct = oli.Id;
        myCtrl.removeProduct();
        
        test.stopTest();
    }
    static testMethod void test3(){
        c_AddProduct.magic();
    }
    
    public static testmethod void createProds(){
        
        TestUtilities.customSettings();
        
        List<Product2> newProds = new List<Product2>();
        Product2 prodGen = new Product2();
        prodGen.Name = 'Genérico';
        prodGen.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(prodGen);
        
        Product2 prod = new Product2();
        prod.Name = 'Test Prod';
        prod.Cor__c = '00;01';
        prod.ProductCode = '81000';
        prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(prod);
        
        Product2 custom = new Product2();
        custom.Name = 'Test Custom';
        custom.Tecnica__c = 'Laser';
        custom.Referencia_relacionada__c = '81000';
        custom.Componente_da_impressao__c = 'Frasco';
        custom.Cores_de_customizacao__c = '2';
        custom.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Customização').getRecordTypeId();
        newProds.add(custom);
        
        insert newProds;
        /*
        List<PricebookEntry> pbes = new List<PricebookEntry>();
        
        PricebookEntry genPbe = new PricebookEntry();
        genPbe.Pricebook2Id = Test.getStandardPricebookId();
        genPbe.Product2Id = prodGen.Id;
        genPbe.CurrencyIsoCode = 'EUR';
        genPbe.UnitPrice = 0;
        genPbe.IsActive = true;
        pbes.add(genPbe);
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id = prod.Id;
        pbe.CurrencyIsoCode = 'EUR';
        pbe.UnitPrice = 0;
        pbe.IsActive = true;
        pbes.add(pbe);
        
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = Test.getStandardPricebookId();
        pbe2.Product2Id = custom.Id;
        pbe2.CurrencyIsoCode = 'EUR';
        pbe2.UnitPrice = 0;
        pbe2.IsActive = true;
        pbes.add(pbe2);
        
        insert pbes;*/
    }
    
}