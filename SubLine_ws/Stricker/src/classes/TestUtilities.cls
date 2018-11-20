public class TestUtilities {
    
    public static void createProds(){
        List<Product2> newProds = new List<Product2>();
        
        Product2 prodExtra = new Product2();
        prodExtra.Name = 'Test Extra';
        prodExtra.ProductCode = 'NSIMPEXTRA';
        prodExtra.isActive = true;
        prodExtra.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(prodExtra);
        
        Product2 prodGen = new Product2();
        prodGen.Name = 'Genérico';
        prodGen.ProductCode = 'NSGEN';
        prodGen.isActive = true;
        prodGen.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(prodGen);
        
        Product2 prod = new Product2();
        prod.Name = 'Test Prod';
        prod.Cor__c = '00;01';
        prod.ProductCode = '81000';
        prod.isActive = true;
        prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(prod);
        
        Product2 nter = new Product2();
        nter.Name = 'nter';
        nter.Cor__c = '00;01';
        nter.ProductCode = 'NSPORTES';
        nter.isActive = true;
        nter.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        newProds.add(nter);
        
        Product2 custom = new Product2();
        custom.Name = 'Test Custom';
        custom.Tecnica__c = 'Laser';
        custom.Referencia_relacionada__c = '81000';
        custom.Componente_da_impressao__c = 'Frasco';
        custom.Cores_de_customizacao__c = '2';
        custom.ProductCode = 'NSTRANSF';
        custom.isActive = true;
        custom.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Customização').getRecordTypeId();
        newProds.add(custom);
        
        insert newProds;
    }
    
    public static void customSettings(){
        Perfil_Integracao__c pi = new Perfil_Integracao__c();
        pi.Name = 'Integrator';
        pi.Endpoint__c = 'https://endpoint.test.pt/';
        
        Perfil_Integracao__c piS = new Perfil_Integracao__c();
        piS.Name = 'Integrator Site';
        piS.Endpoint__c = 'https://endpoint.test.pt/';
        
        Perfil_Integracao__c pi2 = new Perfil_Integracao__c();
        pi2.Name = 'WSDL_Contactos';
        pi2.Endpoint__c = 'https://endpoint.test.pt/';
        
        Perfil_Integracao__c pi3 = new Perfil_Integracao__c();
        pi3.Name = 'WSDL_Claims';
        pi3.Endpoint__c = 'https://endpoint.test.pt/';
        
        Perfil_Integracao__c pi4 = new Perfil_Integracao__c();
        pi4.Name = 'WSDL_Moradas';
        pi4.Endpoint__c = 'https://endpoint.test.pt/';
        
        Perfil_Integracao__c pi5 = new Perfil_Integracao__c();
        pi5.Name = 'WSDL_Viewer';
        pi5.Endpoint__c = 'https://endpoint.test.pt/';
        
        Perfil_Integracao__c pi6 = new Perfil_Integracao__c();
        pi6.Name = 'WSDL_Clientes';
        pi6.Endpoint__c = 'https://endpoint.test.pt/';
        
        insert new List<Perfil_Integracao__c>{pi,pi2,pi3,pi4,pi5,pi6,piS};
        
        Referencias_proibidas_por_pais__c newRefPais = new Referencias_proibidas_por_pais__c();
        newRefPais.Codigo_do_pais__c = 'PT';
        newRefPais.Referencias__c = '82000';
        newRefPais.Name = 'Refs Pais Teste';
        
        insert newRefPais;
        
        Referencias_proibidas_por_dossier__c newRefDossier = new Referencias_proibidas_por_dossier__c();
        newRefDossier.Dossier__c = 'Folha_de_Obra';
        newRefDossier.Name = 'Refs Dossier Teste';
        newRefDossier.Referencias_proibidas__c = '82000';
        
        insert newRefDossier;
        
        Referencias_conjuntas__c newRefConjunta = new Referencias_conjuntas__c();
        newRefConjunta.Referencia_principal__c = '81000';
        newRefConjunta.Referencias_relacionadas__c = '91000';
        newRefConjunta.Name = 'Refs Conjunta Teste';
        
        insert newRefConjunta;
        
        Referencias_Bancarias__c newRefBancaria = new Referencias_Bancarias__c();
        newRefBancaria.Name = 'Millennium BCP';
        newRefBancaria.Banco__c = 'Banco Teste';
        
        Perfil_Integracao__c newPerfil = new Perfil_Integracao__c();
        newPerfil.Name = 'StrickerWSDL';
        newPerfil.Access_Key__c = 'sjraJrN6abvPGZky';
        newPerfil.Endpoint__c = 'http://wsdl.stricker.pt/';
        insert newPerfil;
        
        insert newRefBancaria;
        
        Auxiliar_Clone_Dossier__c auxClone = new Auxiliar_Clone_Dossier__c();
        auxClone.Name = 'Folha_de_Obra';
        auxClone.Rts_Permitidos__c = 'Folha_de_Obra';
        insert auxClone;
    }
    
    public static ResultCreateOpp createOpp(){
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
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.RecordTypeId = [SELECT id from RecordType where DeveloperName ='Folha_de_Obra' and SObjectType = 'Opportunity'].Id;
        opp.CloseDate = system.today();
        opp.Name = 'Opp Teste';
        opp.StageName = 'Aberto';
        opp.CurrencyIsoCode = 'EUR';
        opp.Referencia_PHC__c = '123Teste';
        opp.Email_para_envio_de_maquete__c = 'test@test.pt';
        opp.Stamp__c = 'TestStamp';
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
        oli2.Preco_unitario__c = 1;
        oli2.Preco_aplicado__c = 'Quantidade';        
        insert oli2;
        
        Morada_de_entrega__c morada = new Morada_de_entrega__c(Morada_de_entrega__c='Morada teste',Conta__c=acc.Id,Localidade__c='Localidade teste',Codigo_postal__c='2100-000',Pais__c='PT',Telefone_logistico__c='210035910');
        insert morada;
        
        Expedicao__c exp = new Expedicao__c(Linha_de_transporte__c = oli.Id,Linha_de_despacho__c = oli2.Id, Peso_da_expedicao__c=2,Volume_da_expedicao__c=2,Morada_de_entrega__c=morada.Id,Transportadora__c='CTT',Observacoes_documento__c='Observações documento teste',Dossier__c=opp.Id);
        insert exp;
        
        oli.Expedicao__c = exp.Id;
        oli2.Expedicao__c = exp.Id;
        update new List<OpportunityLineItem>{oli, oli2};
            
        ResultCreateOpp result = new ResultCreateOpp();
        result.opp = opp;
        result.exp = exp;
        result.acc = acc;
        result.morada = morada;
        result.olis.add(oli);
        result.olis.add(oli2);
        
        return result;
    }
    
    public class ResultCreateOpp{
        public Opportunity opp{get;set;}
        public Expedicao__c exp{get;set;}
        public Account acc{get;set;}
        public List<OpportunityLineItem> olis = new List<OpportunityLineItem>();
        public Morada_de_Entrega__c morada {get;set;}
    }
}