@isTest
public class Test_InfoProd {

    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        w_InfoProd.Dossier doss = new w_InfoProd.Dossier(result.opp.Stamp__c, System.now().format('yyyy-mm-dd hh:mm:ss'), '', '0', 'pendente');

        w_InfoProd.updateDossier(doss);
    }
    testmethod static void test2(){
        
        w_InfoProd.Dossier doss = new w_InfoProd.Dossier('', System.now().format('yyyy-mm-dd hh:mm:ss'), '', '0', 'pendente');

        w_InfoProd.updateDossier(doss);
    }
    testmethod static void test3(){
        
        w_InfoProd.Dossier doss = new w_InfoProd.Dossier('StampErrado', System.now().format('yyyy-mm-dd hh:mm:ss'), '', '0', 'pendente');

        w_InfoProd.updateDossier(doss);
    }
    testmethod static void test4(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        w_InfoProd.Dossier doss = new w_InfoProd.Dossier(result.opp.Stamp__c, 'yyyy-mm-dd hh:mm:ss', '', '0', 'pendente');

        w_InfoProd.updateDossier(doss);
    }
}