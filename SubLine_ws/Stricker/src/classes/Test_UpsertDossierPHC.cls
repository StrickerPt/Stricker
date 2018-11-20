@isTest
public class Test_UpsertDossierPHC {
	
    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        sh_UpsertDossierPHC job = new sh_UpsertDossierPHC(result.opp.Id, true);
        
        job.execute(null);
    }	
    testmethod static void test2(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        sh_UpsertDossierPHC job = new sh_UpsertDossierPHC(result.opp.Id, false);
        
        job.execute(null);
    }
}