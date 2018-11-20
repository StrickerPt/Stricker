@isTest
public class Test_CobrancaAlerta {
	
    static testmethod void c_ProdutosPesquisados() {
        
        TestUtilities.customSettings();
        TestUtilities.createProds();
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Documentos_financeiros__c doc = new Documentos_financeiros__c();
        doc.Conta__c = result.acc.Id;
        doc.Tipo_de_documento__c = 1;
        doc.Data_de_validade__c = System.today().addDays(-150);
        doc.Valor_debito_emitido_euros__c = 50;
        doc.Valor_debito_emitido_moeda__c = 50;
        insert doc;
        
        test.startTest();
        c_CobrancaAlerta myCtrl = new c_CobrancaAlerta();
		myCtrl.idAcc = result.acc.Id;
        myCtrl.getAccount();

        myCtrl.getTotal();
        myCtrl.alertType = 1;
        myCtrl.getTotal();
        
        myCtrl.alertType = 2;
        myCtrl.getTotal();
        
        myCtrl.alertType = 3;
        myCtrl.getTotal();

        myCtrl.alertType = 4;
        myCtrl.getTotal();
        myCtrl.getTotalCred();
        myCtrl.getcurrencySymbol();
        
        c_CobrancaAlerta.getLogoUrl();
        
        test.stopTest();
    }
}