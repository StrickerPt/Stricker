@isTest
public class Test_MaquetePipeline {
    static testmethod void test1(){
        
        TestUtilities.createProds();
        TestUtilities.customSettings();
        
        TestUtilities.ResultCreateOpp result = TestUtilities.createOpp();
        
        Opportunity opp = result.opp;
        
        opp.StageName = 'Pedido de maquete';
        checkRecursive.runOpportunityBeforeUpdate = true;
        update opp;
        
        Pedido_de_Maquete__c pm = new Pedido_de_Maquete__c();
        pm.Oportunidade__c = opp.Id;
        pm.Data_de_envio__c = system.now();
        pm.Tipo__c = 'Retificação';
        pm.Destinatario__c = 'Comercial';
        
        Pedido_de_Maquete__c pm2 = pm.clone();
        pm2.Em_atraso__c = true;
        
        Pedido_de_Maquete__c pm3 = pm2.clone();
        pm3.Tipo__c = 'Original';
        
        insert new List<Pedido_de_Maquete__c> {pm, pm2, pm3};
        
        Opportunity opp2 = opp.clone();
        opp2.StageName = 'Aberto';
        insert opp2;
        
        opp2.StageName = 'Pedido de maquete';
        checkRecursive.runOpportunityBeforeUpdate = true;
        update opp2;
        
        delete [Select id from Pedido_de_maquete__c Where oportunidade__c = :opp2.Id];
        
        Pedido_de_Maquete__c pm4 = pm.clone();
        pm4.Oportunidade__c = opp2.Id;
        
        Pedido_de_Maquete__c pm5 = pm.clone();
        pm2.Em_atraso__c = true;
        
        Pedido_de_Maquete__c pm6 = pm2.clone();
        pm3.Tipo__c = 'Original';
        
        insert new List<Pedido_de_Maquete__c> {pm4, pm5, pm6};
            
        Test.setCreatedDate(pm4.Id, System.now().addDays(-1));
        Test.setCreatedDate(pm5.Id, System.now().addDays(-1));
        Test.setCreatedDate(pm6.Id, System.now().addDays(-1));
        
        Test.startTest();
        c_MaquetesPipeline ctrl = new c_MaquetesPipeline();
        
        
        
        c_MaquetesPipeline.getLogoUrl();
        
        ctrl.param1 = 'header';
        ctrl.param2 = 'Pipeline';
        ctrl.buildShowList();
        
        ctrl.param2 = 'Entregues';
        ctrl.buildShowList();
        
        ctrl.param2 = 'Incompletas';
        ctrl.buildShowList();
        
        ctrl.param1 = 'Pipeline';
        ctrl.param2 = 'Em dia';
        ctrl.buildShowList();
        
        ctrl.param2 = 'Em atraso';
        ctrl.buildShowList();
        
        ctrl.param1 = 'Entregues';
        ctrl.param2 = 'Em dia';
        ctrl.buildShowList();
        
        ctrl.param2 = 'Em atraso';
        ctrl.buildShowList();
        
        ctrl.param1 = 'Incompletas';
        ctrl.buildShowList();
        
        ctrl.param2 = 'Em dia';
        ctrl.buildShowList();
        
        ctrl.param2 = 'Em atraso';
        ctrl.buildShowList();
        
        Test.stopTest();
    }
}