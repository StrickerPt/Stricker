@isTest
public class Test_ViewerContaCorrente {
	static testmethod void c_ViewerContaCorrente() {
        test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.acc);
        c_ViewerContaCorrente myCtrl = new c_ViewerContaCorrente(ctrl);
                
        myCtrl.init();
        myCtrl.mostrarEmFalta();
        test.stopTest();
    }

}