@isTest
public class Test_AdminPage {
    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        c_AdminPage ctrl = new c_AdminPage();
        ctrl.dossiers.pagina = 1;
        ctrl.dossiersWeb.pagina = 1;
        ctrl.correrBatchDossier();
        ctrl.correrBatchDossierWeb();
        ctrl.terminarBatchDossier();
        ctrl.terminarBatchDossierWeb();
    }
}