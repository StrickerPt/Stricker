@isTest
public class Test_AtribZonas {

    static testmethod void Test_AtribZonas() {
        TestUtilities.customSettings();
        Lead lead = new Lead(LastName='Test',Company='Test Empresa',Numero_de_contribuinte__c='506842576',Prefixo_de_contribuinte__c='PT', CountryCode='PT');
        lead.PostalCode = '1800-200';
        insert lead;
        
        Atribuicao_de_zonas__c atb = new Atribuicao_de_zonas__c();
        atb.Assistente__c = Userinfo.getUserId();
        atb.Comercial__c = Userinfo.getUserId();
        atb.Pais__c = 'PT';
        insert atb;
        
        Atribuicao_de_zonas__c atb2 = new Atribuicao_de_zonas__c();
        atb2.Assistente__c = Userinfo.getUserId();
        atb2.Comercial__c = Userinfo.getUserId();
        atb2.Pais__c = 'ES';
        insert atb2;
        
        Atribuicao_de_zonas__c atb3 = new Atribuicao_de_zonas__c();
        atb3.Assistente__c = Userinfo.getUserId();
        atb3.Comercial__c = Userinfo.getUserId();
        atb3.Pais__c = 'ES';
        insert atb3;
        
        atb.Codigo_postal_Minimo__c = '1800';
        atb.Codigo_postal_Maximo__c = '2000';
        atb2.Codigo_postal_Minimo__c = '2200';
        atb2.Codigo_postal_Maximo__c = '2400';
        atb3.Codigo_postal_Minimo__c = '2401';
        atb3.Codigo_postal_Maximo__c = '2600';
        update new List<Atribuicao_de_zonas__c>{ atb, atb2 , atb3};
        
        Lead lead2 = new Lead(LastName='Test',Company='Test Empresa',Numero_de_contribuinte__c='123456789',Prefixo_de_contribuinte__c='PT', CountryCode='PT');
        lead2.PostalCode = '1800-200';
        
        Lead lead3 = new Lead(LastName='Test2',Company='Test2 Empresa2',Numero_de_contribuinte__c='46576086M',Prefixo_de_contribuinte__c='ES', CountryCode='ES');
        lead3.PostalCode = '2200-200';
        insert new List<Lead>{lead2, lead3};
            
        Account acc = new Account();
        acc.Name = 'Conta Teste';
        acc.Tabela_de_precos__c = '1';
        acc.Bloqueado__c = false;
        acc.Assistente_comercial__c = UserInfo.getUserId();
        acc.CurrencyIsoCode = 'EUR';
        acc.BillingCountryCode = 'PT';
        acc.BillingPostalCode = '1800-200';
        acc.Encomendas_canceladas__c = false;
        acc.Prefixo_pais_de_contribuinte__c = 'PT';
        
        Account acc2 = new Account();
        acc2.Name = 'Conta Teste';
        acc2.Tabela_de_precos__c = '1';
        acc2.Bloqueado__c = false;
        acc2.Assistente_comercial__c = UserInfo.getUserId();
        acc2.CurrencyIsoCode = 'EUR';
        acc2.BillingCountryCode = 'ES';
        acc2.BillingPostalCode = '2000-200';
        acc2.Encomendas_canceladas__c = false;
        acc2.Prefixo_pais_de_contribuinte__c = 'ES';
        insert new List<Account>{acc, acc2};
            
            b_AtribZonasAccounts batch = new b_AtribZonasAccounts(new Set<Id>{acc.Id, acc2.Id}, false);
        batch.mapAccountFields(acc, new Atribuicao_de_zonas__c());
    }
}