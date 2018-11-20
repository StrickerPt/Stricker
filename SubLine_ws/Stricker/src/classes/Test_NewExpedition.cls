@isTest
public class Test_NewExpedition {
	static testmethod void c_NewExpedition() {
        test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        PageReference pageRef = Page.p_NewExpedition;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id',result.opp.Id);
        
        ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(new List<Expedicao__c>{result.exp});
        c_NewExpedition myCtrl = new c_NewExpedition(ctrl);
        myCtrl.copiaMoradaOnline();
        myCtrl.reCheckIntegration();
        myCtrl.dummyMethod();
        myCtrl.moradas.get(0).get(0).selected = true;
        myCtrl.criaMorada();
        myCtrl.checkMoradas();
        myCtrl.selectProds();
        myCtrl.checkLinhas();
        myCtrl.tranportadoras.get(0).selected = true;
        myCtrl.checkTransportadoras();
        myCtrl.sendFailureEmail('message');
        myCtrl.filterDir = '___';
        myCtrl.applyFilterDir();
        test.stopTest();
    }
}