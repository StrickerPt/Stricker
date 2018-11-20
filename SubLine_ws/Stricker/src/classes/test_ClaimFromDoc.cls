@isTest
public class test_ClaimFromDoc {
    @isTest static void test_ClaimFromDoc() {
        Test.startTest(); 
        TestUtilities.customSettings();
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.Numero_de_cliente__c = '57981';
        acc.Encomendas_canceladas__c = false;
        insert acc;
        
        Documentos_financeiros__c d = new Documentos_financeiros__c();
        d.Conta__c =  acc.id;
        d.Ftstamp__c = ''; 
        d.Valor_credito_emitido_moeda__c = 0; 
        d.Valor_credito_emitido_euros_regularizado__c =  0;
        d.Valor_credito_emitido_euros__c =  0;
        d.Valor_credito_emitido_moeda_regularizado__c =  0;
        d.Data_de_pagamento__c =  system.today() +10;
        d.Valor_debito_emitido_moeda_regularizado__c =  0;
        d.Valor_debito_emitido_euros_regularizado__c =  0;
        d.Valor_debito_emitido_euros__c =  0;
        d.Valor_debito_emitido_moeda__c =  0;
        d.CurrencyIsoCode =  'EUR';
        d.Tipo_de_documento__c =  1;
        d.Data__c =  system.today();
        d.Data_de_validade__c =  system.today() + 10;
        insert d;    
        
        List<UtilClaims.LinhasDoc> l = new List<UtilClaims.LinhasDoc>();
        
        ApexPages.StandardController std = new ApexPages.StandardController(d);
        c_ClaimFromDoc controller = new c_ClaimFromDoc(std);
        controller.claimDoc = ''; 
        controller.linhas = l;
        
        Test.stopTest();
    }
}