@isTest
public class Test_ViewerEncomendasCativar {
	static testmethod void c_ViewerEncomendasCativar() {
        test.startTest();
        
        TestUtilities.createProds();
        TestUtilities.customSettings();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        c_ViewerEncomendasCativar myCtrl = new c_ViewerEncomendasCativar();
        myCtrl.oppToSearch = result.opp.Referencia_PHC__c;
        myCtrl.getOppId();
        
        myCtrl.oppToSearch = result.opp.Referencia_PHC__c;
        myCtrl.cativarStock();
        
        test.stopTest();
    }
}