@isTest
public class Test_SalesforcePSWebService {
    @isTest static void testSalesforcePSWebService() {
        
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
        
        Opportunity opp = new Opportunity();
        opp.AccountId = acc.Id;
        opp.RecordTypeId = [SELECT id from RecordType where DeveloperName ='Folha_de_Obra' and SObjectType = 'Opportunity'].Id;
        opp.CloseDate = system.today();
        opp.Name = 'Opp Teste';
        opp.StageName = 'Aberto';
        opp.CurrencyIsoCode = 'EUR';
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.Stamp__c = '1234';
        insert opp;
        
        w_SalesforcePSWebService.dossierImpresso('1234', true);
        
        w_SalesforcePSWebService.dossierImpressoList(new List<String>{'1234'}, true);
    }
    
     
    testmethod static void testUpsertClient() {
        
        TestUtilities.customSettings();
        
        w_SalesforcePSWebService.Cliente cliente = new w_SalesforcePSWebService.Cliente();
        
        cliente.no = '123';
        cliente.bloqueado = false;
        cliente.inativo = false;
        cliente.tipo = '';
        cliente.enc_canceladas = false;
        cliente.contencioso = false;
        cliente.tab_precos = '';
        cliente.obj_fat = 0;
        cliente.div_nao_titulada_maturidade = 0;
        cliente.div_nao_titulada_saldo = 0;
        cliente.div_titulada_maturidade = 0;
        cliente.div_titulada_saldo = 0;
        cliente.lim_cred_comercial = 0;
        cliente.lim_oper_divida = 0;
        cliente.plafond_comercial = 0;
        cliente.plafond_operacional = 0;
        cliente.tipo_fat = '';
        cliente.tax_iva = 0;
        cliente.merc_cust = '';
        cliente.nomeEmpresa = '';
        cliente.tabIVA = 0;
        cliente.dir_comercial = '';
        cliente.preNIF = '';
        cliente.nif = '';
        cliente.nomeab = '';
        cliente.divida_vencida = 0;
        cliente.escalao_hidea = '';
        cliente.pais = '';
        cliente.local = '';
        cliente.morada = '';
        cliente.cod_post = '';
        cliente.vend_nome = '';
        cliente.assistent = '';
        cliente.doc_dest = '';
        cliente.idioma_fat = '';
        cliente.website = '';
        cliente.phone = '';
        cliente.email = '';
        cliente.merc = '';
        cliente.macro = '';
        cliente.area = '';
        cliente.idioma = '';
        cliente.email_docs = '';
        cliente.moeda = '';
        cliente.esc_standard = false;
        cliente.iban = '';
        cliente.notas = '';
        cliente.rappel = '';
        cliente.incentiv = '';
        cliente.catalogo = '';
        cliente.amostras = '';
        cliente.descefec = 0;
        
        w_SalesforcePSWebService.clientUpsert(cliente);
    }
    
         
    testmethod static void testUpsertContact() {
        
        TestUtilities.customSettings();
        
        w_SalesforcePSWebService.contactUpsert(new w_SalesforcePSWebService.Contacto());
    }
    
    testmethod static void testDeleteContact() {
        
        TestUtilities.customSettings();
        
        w_SalesforcePSWebService.contactDelete('', '');
    }
    
    testmethod static void testUpsertMorada() {
        
        TestUtilities.customSettings();
        
        w_SalesforcePSWebService.moradaClienteUpsert(new w_SalesforcePSWebService.MoradaCliente());
    }
    testmethod static void testDeleteMorada() {
        
        TestUtilities.customSettings();
        
        w_SalesforcePSWebService.moradaClienteDelete('', '');
    }
}