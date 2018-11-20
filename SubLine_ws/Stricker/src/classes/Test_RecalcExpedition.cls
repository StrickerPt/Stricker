@isTest
public class Test_RecalcExpedition {
    static testmethod void test1(){
        test.startTest();
        
        TestUtilities.createProds();
        TestUtilities.customSettings();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        b_RecalcExpedition batch = new b_RecalcExpedition(new Set<Id>{result.exp.Id});
        Database.executeBatch(batch);
        batch.execute(null);
        test.stopTest();
    }
}