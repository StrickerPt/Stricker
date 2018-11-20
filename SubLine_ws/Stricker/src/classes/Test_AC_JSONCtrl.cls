@isTest
public class Test_AC_JSONCtrl {
	
    static testmethod void AC_JSONCtrl() {
        test.startTest();
        createProds();
        PageReference pageRef = Page.p_addProduct;
        Test.setCurrentPage(pageRef);
        
        String euro = 'EUR';
        String pricebook = 'IsActive = true'
            +' and Pricebook2Id = \''+Test.getStandardPricebookId()+'\''
            + ' And CurrencyIsoCode = \'' + euro+'\'';
        
        ApexPages.currentPage().getParameters().put('q', '81000');
        ApexPages.currentPage().getParameters().put('obj', 'PricebookEntry');
        ApexPages.currentPage().getParameters().put('label', 'ProductCode,Product2.Tamanho__c');
        ApexPages.currentPage().getParameters().put('detail', 'Product2.Nome_para_user__c,CurrencyIsoCode');
        ApexPages.currentPage().getParameters().put('wc', pricebook);
        ApexPages.currentPage().getParameters().put('lm', '10');
        ApexPages.currentPage().getParameters().put('value', 'Product2Id');
        
        AC_JSONCtrl ac = new AC_JSONCtrl();
        String testAC = ac.getJSON();
        
        test.stopTest();
    }
    
    public static testmethod void createProds(){
        
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
        
        
    }
}