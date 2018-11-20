@isTest
public class Test_UpdateClient {
    @isTest static void testUpdateClient() {
        Test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        result.acc.Numero_de_cliente__c = '1';
        update result.acc;
        
        b_UpdateClient b1 = new b_UpdateClient();
        b_UpdateClient b2 = new b_UpdateClient(1);
        b_UpdateClient.GetCRONExpression(System.now());
        b1.execute(null);
        
        Test.stopTest();
    }
    
    
    @isTest static void testUpdateClientSchedule() {
        Test.startTest();
        
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        sh_UpdateClient upClient = new sh_UpdateClient(new Set<Id>{result.acc.Id});
        upClient.execute(null);
        
        Test.stopTest();
    }
}