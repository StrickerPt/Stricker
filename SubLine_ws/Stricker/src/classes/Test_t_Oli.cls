@isTest
public class Test_t_Oli {
    testmethod static void test1(){
        Test.startTest();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        OpportunityLineItem item = [Select Id From OpportunityLineItem Limit 1];
        checkRecursive.runOpportunityAfterUpdate = true;
        item.Peso__c = 5;
        item.Volume__c = 5;
        update item;
        Test.stopTest();
    }
    @TestSetup
    public static void setup(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
    }
}