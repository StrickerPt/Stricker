@isTest
public class Test_WidgetFailures {
    testmethod static void test1(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        result.opp.Erro_comunicacao__c = true;
        result.opp.Description = 'Teste erro';
        
        update result.opp;
        
        c_WidgetFailures ctrl = new c_WidgetFailures();
        ctrl.checkNewErrors();
        
        system.debug(ctrl.myDossiers);
        ctrl.sendId = result.opp.Id;
        
        ctrl.resendDossier();
    }
}