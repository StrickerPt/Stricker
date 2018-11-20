@isTest
public class Test_ImportarPrecosCliente {
    testmethod static void test(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.acc.Numero_de_cliente__c = '9644';
        update result.acc;
        ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(new List<Account>{result.acc});
        
        c_ImportarPrecosCliente controller = new c_ImportarPrecosCliente(ctrl);
        
        controller.fileName = 'test';
        controller.getOperations();
        //sem linhas
        controller.blobFile = 'data:application/vnd.ms-excel;base64,TnVtZXJvIGRlIGNsaWVudGU7UHJvZHV0bztWYWxvcjtEYXRhIGRlIGluaWNpbztEYXRhIGRlIGZpbQ0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0K';
        controller.processFile();
        
        controller.blobFile = 'data:application/vnd.ms-excel;base64,TnVtZXJvIGRlIGNsaWVudGU7UHJvZHV0bztWYWxvcjtEYXRhIGRlIGluaWNpbztEYXRhIGRlIGZpbQ0KOTY0NDs4MTAwMDsxOzAxLzAxLzIwMTg7MDEvMDEvMjAxOQ0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0K';
        
        controller.processFile();
        
        controller.selectedOperation = 'delete';
        
        controller.processFile();
    }
    
    testmethod static void test2(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.acc.Numero_de_cliente__c = '9644';
        update result.acc;
        
        ApexPages.currentPage().getParameters().put('id', result.acc.Id);
        Preco_por_cliente__c ppc = new Preco_por_cliente__c();
        
        ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(new List<Preco_por_cliente__c>{ppc});
        
        c_ImportarPrecosCliente controller = new c_ImportarPrecosCliente(ctrl);
        
        controller.fileName = 'test';
        controller.getOperations();
        //sem linhas
        controller.blobFile = 'data:application/vnd.ms-excel;base64,TnVtZXJvIGRlIGNsaWVudGU7UHJvZHV0bztWYWxvcjtEYXRhIGRlIGluaWNpbztEYXRhIGRlIGZpbQ0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0K';
        controller.processFile();
        
        controller.blobFile = 'data:application/vnd.ms-excel;base64,TnVtZXJvIGRlIGNsaWVudGU7UHJvZHV0bztWYWxvcjtEYXRhIGRlIGluaWNpbztEYXRhIGRlIGZpbQ0KOTY0NDs4MTAwMDsxOzAxLzAxLzIwMTg7MDEvMDEvMjAxOQ0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0KOzs7Ow0K';
        
        controller.processFile();
        
        controller.selectedOperation = 'delete';
        
        controller.processFile();
    }
}