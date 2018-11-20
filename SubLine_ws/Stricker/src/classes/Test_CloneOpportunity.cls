@isTest
public class Test_CloneOpportunity {
	static testmethod void c_CloneOpportunity() {
        test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_CloneOpportunity myCtrl = new c_CloneOpportunity(ctrl);
        
        myCtrl.olis.get(0).selected = true;
        myCtrl.pickedRt = 'Folha_de_Obra';
        myCtrl.calcPrecos = true;
        myCtrl.clonarDossier();
        
        test.stopTest();
    }
}