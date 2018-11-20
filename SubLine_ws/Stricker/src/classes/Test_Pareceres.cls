@isTest
public class Test_Pareceres {
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
        
        Pedido_de_parecer__c parecer = new Pedido_de_parecer__c();
        parecer.Produto_do_pedido__c = item.Id;
        parecer.Reclamacao__c = caso.Id;
        parecer.Departamento__c = 'Informática';
        parecer.Tipologia__c = 'Falha processual';
        
        insert parecer;
        
        ApexPages.StandardController std = new ApexPages.StandardController(parecer);
        
        c_Pareceres ctrl = new c_Pareceres(std);
        
        ctrl.callExtraInfo();
        
        ctrl.updateField = 'Pedido_de_recolha__c';
        ctrl.updateValue = 'true';
        ctrl.escreverValor();
        
        ctrl.blobFile = '123';
        ctrl.fileName = '123';
        ctrl.newFile();
        
        ctrl.getFicheirosLinha();
        
        ctrl.getParecerPrefix();
        
        ctrl.getListViewId();
        
        ctrl.getMaquete();
        
        ctrl.getHistorico();
    }
}