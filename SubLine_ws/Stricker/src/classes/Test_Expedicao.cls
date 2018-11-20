@isTest
public class Test_Expedicao {
    static testmethod void Expedicao1() {
        Test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Test.stopTest();
    }
    
    static testmethod void Expedicao2() {
        Test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        delete [Select Id From Expedicao__c Limit 1];
        Test.stopTest();
    }
    
}