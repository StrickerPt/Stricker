@isTest
public class Test_ValidarMoradaOnline {
	static testmethod void c_ValidarMoradaOnline() {
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        result.opp.Codigo_postal_online__c = 'Teste';
        result.opp.Morada_de_entrega_online__c = 'Teste';
        
        update result.opp;
        
        test.startTest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_ValidarMoradaOnline myCtrl = new c_ValidarMoradaOnline(ctrl);
        
        myCtrl.criarNovaMorada();
        
        ApexPages.StandardController ctrl2 = new ApexPages.StandardController(result.opp);
        c_ValidarMoradaOnline myCtrl2 = new c_ValidarMoradaOnline(ctrl2);
        
        myCtrl2.moradas.get(0).selected =true;
        myctrl2.associarMorada();
        myCtrl2.clearMessages();
        
        test.stopTest();
    }
}