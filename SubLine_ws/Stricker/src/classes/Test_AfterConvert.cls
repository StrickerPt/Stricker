@isTest
public class Test_AfterConvert {
    testmethod static void test1(){
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        sh_AfterConvert.createSiteUser(new SEt<ID>{result.acc.Id});
        
    }
}