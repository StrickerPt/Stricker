@isTest
public class Test_DocumentosFinanceiros {

    @isTest static void testDocumentosFinanceiros() {
        Test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        result.acc.Numero_de_cliente__c = '1';
        update result.acc;
        
        new b_DocumentosFinanceiros().execute(null);
        
        Test.stopTest();
    }
}