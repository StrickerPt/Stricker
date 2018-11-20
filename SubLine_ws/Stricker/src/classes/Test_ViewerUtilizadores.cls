@isTest
public class Test_ViewerUtilizadores {
    static testmethod void c_ViewerUtilizadores() {
        test.startTest();
        
        TestUtilities.customSettings();
        
        TestUtilities.createProds();

        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.acc);
        c_ViewerUtilizadores myCtrl = new c_ViewerUtilizadores(ctrl);
        
        myCtrl.init();
        myCtrl.resetPassword();
        myCtrl.clearPass();
        myCtrl.getLinguas();
        myCtrl.getAcessos();
        myCtrl.submitUser();
        myCtrl.inactivarUser();
        
        test.stopTest();
    }
    
}