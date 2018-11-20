@isTest
public class Test_NewOpportunity {
    static testmethod void c_NewOpportunity() {
        test.startTest();
        TestUtilities.customSettings();
        TestUtilities.createProds();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        PageReference pageRef = Page.p_NewOpportunity;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('accid',result.acc.id);
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_NewOpportunity myCtrl = new c_NewOpportunity(ctrl);
        myCtrl.selectedRT = [Select Id, Name, Description From RecordType Where SobjectType = 'Opportunity' and DeveloperName = 'Orcamento'].Id;
        myCtrl.createDummyOpp();
        myCtrl.opp.StageName = 'Aberto';
        myCtrl.docDest();
        myCtrl.opp.Documento_de_destino__c = 'Guia de Remessa';
        myCtrl.opp.Destino_de_impressao__c = 'Normal';
        myCtrl.insertOpp();
        
        test.stopTest();
    }
}