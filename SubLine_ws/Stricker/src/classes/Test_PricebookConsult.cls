@isTest
public class Test_PricebookConsult {
    static testmethod void Test_PricebookConsult() {
        
        Product2 prod = new Product2();
        prod.Name = 'Test Prod';
        prod.Cor__c = '00;01';
        prod.ProductCode = '81000';
        prod.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Produto').getRecordTypeId();
        insert prod;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(prod);
        
        c_PricebookConsult ctrl = new c_PricebookConsult(controller);
        
    }

}