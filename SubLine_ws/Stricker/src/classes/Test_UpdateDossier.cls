@isTest
public class Test_UpdateDossier {
    @isTest static void testUpdateDossier() {
        Test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        result.acc.Numero_de_cliente__c = '1';
        update result.acc;
        
        b_UpdateDossier b1 = new b_UpdateDossier();
        b_UpdateDossier.reprogramSelf();
        b1.execute(null);

        Test.stopTest();
    }
    
    testmethod static void test2(){
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        result.acc.Numero_de_cliente__c = '1';
        update result.acc;
        
        b_UpdateDossierWeb b3 = new b_UpdateDossierWeb();
        b_UpdateDossierWeb.reprogramSelf();
        b3.execute(null);
    }
}