@isTest
public class Test_UpdateLinesAddress {

    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        b_UpdateLinesAddress batch = new b_UpdateLinesAddress(new Set<Id>{result.morada.Id});
        Database.executeBatch(batch);
    }
}