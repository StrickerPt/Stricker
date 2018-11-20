@isTest
public class Test_NewClaim {
    
    
    @isTest static void test_NewClaim() {
        
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
        
        Token_site__c t = new Token_site__c();
        t.Numero_de_cliente__c = acc.Numero_de_cliente__c;
        t.Token__c = ''; 
        t.Ip__c = '';
        t.Endereco_de_retorno__c = '';
        t.Data_de_entrada__c = system.today() - 1;
        t.Data_de_validade__c= system.today() + 50;
        t.Duracao__c = 10;
        t.Validado__c = true;
        insert t;
        
        
        
        Test.setCurrentPageReference(new PageReference('Page.p_NewClaim')); 
        System.currentPageReference().getParameters().put('no', acc.Numero_de_cliente__c);
        System.currentPageReference().getParameters().put('lang', 'PT');
        System.currentPageReference().getParameters().put('validClient', 'true');
        
        
        c_NewClaim c = new c_NewClaim();
        c.bostamp ='xptoStamp';
        c.ftstamp ='FT2008XX';
        c.ficheiroEscolhido = 'maquete.pdf' ;
        c.selectedLine = Json.serialize(new UtilClaims.NewClaimLine('name', 'ftstamp', 'bostamp', null));
        c.checkPermaValidate();
        
        // ir para estagio seguinte
        c.nextStage();
        
        // ir paar anterior 
        c.backStage();
        
        
        //segunda parte do teste ( bater )
        
        
        Test.setCurrentPageReference(new PageReference('Page.p_NewClaim')); 
        System.currentPageReference().getParameters().put('no', '8888888');
        System.currentPageReference().getParameters().put('lang', 'PT');
        System.currentPageReference().getParameters().put('validClient', 'true');
        
        c_NewClaim c1 = new c_NewClaim();
        
        c1.checkPermaValidate();
        
        
        Test.stopTest();
    }
    
}