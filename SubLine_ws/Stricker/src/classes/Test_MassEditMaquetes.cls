@isTest
public class Test_MassEditMaquetes {
    static testmethod void test1() {
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Test.startTest();
        ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(new List<Opportunity>{result.opp});
        ctrl.setSelected(new List<Opportunity>{result.opp});
        c_MassEditMaquetes myCtrl = new c_MassEditMaquetes(ctrl);
        myCtrl.myOpp.Designer__c = Opportunity.Designer__c.getDescribe().getPicklistValues().get(0).getValue();
        myCtrl.updateOpps();
        Test.stopTest();
    }
}