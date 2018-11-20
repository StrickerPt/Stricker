@isTest
public class Test_UtilClaims {
    testmethod static void compareValues(){
        
        UtilClaims.compareValues(null, '');
        UtilClaims.compareValues('123', '123');
        UtilClaims.compareValues(null, '123');
    }
    
    testmethod static void sendEmailFailure(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.createOpp();
        
        UtilClaims.sendEmailFailure('TEst','Boddy');
    }
    
    testmethod static void LinhasDoc(){
        UtilClaims.LinhasDoc linha = new UtilClaims.LinhasDoc();
        UtilClaims.LinhasDoc linha2 = new UtilClaims.LinhasDoc('','');
        UtilClaims.LinhasDoc linha3 = new UtilClaims.LinhasDoc('String ftstamp', 'String bostamp','String uniqueId', new wsdl_Claims.LinDocFinCliente());
        
        List<UtilClaims.LinhasDoc> linhas = new List<UtilClaims.LinhasDoc>{linha , linha2, linha3};
            linhas.sort();
        
        UtilClaims.LinhasDoc linha4 = linha3.cloneThis();
        linha4.get('');
    }
    
    testmethod static void validateToken(){
        UtilClaims.validateToken('testToken', new Token_Site__c(Token__c = 'testToken', Data_de_validade__c = system.now().addMinutes(5)));
    }
    
    testmethod static void permaValidateToken(){
        Token_Site__c token = new Token_Site__c();
        insert token;
        
        UtilClaims.permaValidateToken(token.Id);
    }
    
    testmethod static void verificarCaso(){
        TestUtilities.createProds();
        TestUtilities.customSettings();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Case caso = new Case();
        caso.AccountId = result.acc.Id;
        insert caso;
        
        Order pedido = new Order(); 
        pedido.Pricebook2Id = Test.getStandardPricebookId();
        pedido.AccountId = result.acc.id;
        pedido.EffectiveDate = date.today();
        pedido.Status = 'Novo';
        pedido.CurrencyIsoCode = 'EUR';
        pedido.Reclamacao__c = caso.Id;
        insert pedido;
        
        OrderItem item= new OrderItem();
        item.Pais__c = 'PT';
        item.OrderId = pedido.id; 
        item.Quantity = 1; 
        item.UnitPrice = 2; 
        item.Referencia_SKU__c = '52'; 
        item.PricebookEntryId = [Select Id From PricebookEntry Where Pricebook2Id = :pedido.Pricebook2Id and CurrencyIsoCode = :pedido.CurrencyIsoCode Limit 1].Id;
        item.Reclamacao__c = caso.Id;
        insert item;
        
        UtilClaims.verificarCaso(caso, new List<Pedido_de_parecer__c>{new Pedido_de_parecer__c()});
    }
    
    testmethod static void NewClaimLine(){
        UtilClaims.NewClaimLine linha = new UtilClaims.NewClaimLine('String name', 'String ftstamp', 'String bostamp', null);
        UtilClaims.NewClaimLine linha2 = new UtilClaims.NewClaimLine(new wsdl_Claims.DocFinCliente());
        UtilClaims.NewClaimLine linha3 = new UtilClaims.NewClaimLine(new wsdl_Claims.DossierByCliente());
        UtilClaims.NewClaimLine linha4 = new UtilClaims.NewClaimLine(new Documentos_financeiros__c());
        
        linha2.get('');
    }
    
    testmethod static void Fatura(){
        UtilClaims.Fatura fat = new UtilClaims.Fatura('String name', 'String ftstamp', 'String bostamp', system.now());
    }
    
    testmethod static void Morada(){
       UtilClaims.Morada mor = new UtilClaims.Morada('String rua','String codPost','String local','String pais','String transp');
    }
}