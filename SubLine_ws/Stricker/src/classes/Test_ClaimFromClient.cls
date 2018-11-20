@isTest
public class Test_ClaimFromClient {
    testmethod static void test1(){
        
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
        item.Tipologia__c = 'Falha processual';
        insert item;
        
        ApexPages.StandardController std = new ApexPages.StandardController(caso);
        
        c_ClaimFromClient ctrl = new c_ClaimFromClient(std);
        ctrl.selectedLine = Json.serialize(new UtilClaims.NewClaimLine('String name', 'String ftstamp', 'String bostamp',new List<UtilClaims.Fatura>()));
        ctrl.nextStage();
        
        ctrl.backStage();
        
        ctrl.filter = '1';
        ctrl.applyFilter();
        
        ctrl.setAccount();
        
        ctrl.confirmNumCLi();
    }
}