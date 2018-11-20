@isTest
public class Test_Maquete {
	
	static testmethod void c_maquete() {
        test.startTest();
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        result.opp.Estado_da_maquete__c = 'Em aprovação do cliente';
        
        update result.opp;
        
        PageReference pageRef = Page.maquete;
        pageRef.getParameters().put('id', result.opp.Id);
        Test.setCurrentPage(pageRef);
        
        c_maquete myCtrl = new c_maquete();
        //c_maquete.getLogoUrl();
        
        myCtrl.motivo = 'Teste';
        myCtrl.dummyBlob = Blob.valueOf('Teste');
        myCtrl.content.Body = Blob.valueOf('Teste 2');
        myCtrl.content.Name = 'Teste 2';
        
        myCtrl.retificar();
        myCtrl.enviar();
        myCtrl.aprovar();
        myCtrl.uploadFile();
        
        test.stopTest();
    }    
    
}