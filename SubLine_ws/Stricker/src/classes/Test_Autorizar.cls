@isTest
public class Test_Autorizar {
    static testmethod void test1() {
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Estado_da_maquete__c = null;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        myCtrl.updateRecord();
        
        test.stopTest();
        
    }
    
    static testmethod void test2() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = null;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        myCtrl.updateRecord();
        
        test.stopTest();
    }
    
    
    static testmethod void test3() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = 'Aprovada';
        result.opp.Destino_de_impressao__c = 'Normal';
        result.opp.Documento_de_destino__c = 'Guia de Remessa';
        result.opp.N_de_versao_de_maquete_aceite__c = 1;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        myCtrl.updateRecord();
        
        test.stopTest();
    }
    static testmethod void test4() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = 'Aprovada';
        result.opp.Destino_de_impressao__c = 'Normal';
        result.opp.Documento_de_destino__c = 'Guia de Remessa';
        result.opp.Autorizada__c = 'SF';
        result.opp.N_de_versao_de_maquete_aceite__c = 1;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        myCtrl.updateRecord();
        
        test.stopTest();
    }
    static testmethod void test5() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = 'Aprovada';
        result.opp.Destino_de_impressao__c = 'Normal';
        result.opp.Documento_de_destino__c = 'Guia de Remessa';
        result.opp.Autorizada__c = 'SF';
        result.opp.N_de_versao_de_maquete_aceite__c = 1;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        myCtrl.reCheckIntegration();
        myCtrl.goBack();
        
        test.stopTest();
    }
    static testmethod void test6() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = 'Aprovada';
        result.opp.Destino_de_impressao__c = 'Normal';
        result.opp.Documento_de_destino__c = 'Guia de Remessa';
        result.opp.Autorizada__c = 'SF';
        result.opp.Impresso__c = true;
        result.opp.N_de_versao_de_maquete_aceite__c = 1;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        myCtrl.updateRecord();
        
        test.stopTest();
    }
    static testmethod void test7() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = 'Aprovada';
        result.opp.Destino_de_impressao__c = 'Normal';
        result.opp.Documento_de_destino__c = 'Guia de Remessa';
        result.opp.Autorizada__c = 'SF';
        result.opp.N_de_versao_de_maquete_aceite__c = 1;
        
        Profile_Id__mdt adminId = [Select Id__c From Profile_Id__mdt Where DeveloperName = 'Administrador_do_sistema'];
        
        User testUser = [Select Id From User Where isActive = true And ProfileId != :adminId.Id__c Limit 1];
        
        result.opp.OwnerId = testUser.Id;
        update result.opp;
        System.runAs(testUser){
            
            test.startTest();
            
            ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
            c_Autorizar myCtrl = new c_Autorizar(ctrl);
            
            myCtrl.updateRecord();
            
            test.stopTest();
        }
    }
    static testmethod void test8() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        List<OpportunityLineItem> olis = [Select Id From OpportunityLineItem];
        for(OpportunityLineItem oli : olis){
            oli.Stock_cativo__c = false;
        }
        update olis;
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = null;
        result.opp.RecordTypeId = [Select Id From RecordType where DeveloperName = 'Reserva' And SObjectType = 'Opportunity'].Id;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        
        myCtrl.updateRecord();
        
        test.stopTest();
        
    }
    
    static testmethod void test9() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        List<OpportunityLineItem> olis = [Select Id From OpportunityLineItem];
        for(OpportunityLineItem oli : olis){
            oli.Stock_cativo__c = false;
        }
        update olis;
        result.opp.Stamp__c = 'null';
        result.opp.Estado_da_maquete__c = null;
        result.opp.RecordTypeId = [Select Id From RecordType where DeveloperName = 'Nota_de_encomenda' And SObjectType = 'Opportunity'].Id;
        result.opp.Motivo_de_pendente__c = 'Aviado';
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        myCtrl.updateRecord();
        
        test.stopTest();
        
    }
    static testmethod void test10() {
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        result.opp.Stamp__c = null;
        result.opp.Estado_da_maquete__c = null;
        update result.opp;
        
        test.startTest();
        
        ApexPages.StandardController ctrl = new ApexPages.StandardController(result.opp);
        c_Autorizar myCtrl = new c_Autorizar(ctrl);
        
        
        myCtrl.updateRecord();
        
        test.stopTest();
        
    }
    
    @TestSetup
    public static void setup(){
        TestUtilities.customSettings();
        TestUtilities.createProds();
    }
}