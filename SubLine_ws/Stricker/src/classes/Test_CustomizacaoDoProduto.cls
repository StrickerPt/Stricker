@isTest
public class Test_CustomizacaoDoProduto {
	
    static testmethod void c_CustomizacaoDoProduto() {
    	test.startTest();
        
        createProds();

        ApexPages.StandardController ctrl = new ApexPages.StandardController(createProds());
        c_CustomizacaoDoProduto myCtrl = new c_CustomizacaoDoProduto(ctrl);

        test.stopTest();    
    }
    
    public static testmethod Product2 createProds(){
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
        custom.Referencia_relacionada__c = '81000';
        custom.Componente_da_impressao__c = 'Frasco';
        custom.Cores_de_customizacao__c = '2';
        custom.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Customização').getRecordTypeId();
        newProds.add(custom);
        
        insert newProds;
        
        return prod;
    }
}