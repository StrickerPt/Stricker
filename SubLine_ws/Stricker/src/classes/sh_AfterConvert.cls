public class sh_AfterConvert implements Schedulable{
    public Set<Id> accsId;
    public Set<Id> addIds;
    public Set<Id> contIds;
    
    public sh_AfterConvert(Set<Id> accsId, Set<Id> addIds, Set<Id> contIds){
        this.accsId = accsId;
        this.addIds = addIds;
        this.contIds = contIds;
        
    }
    
    public void execute(SchedulableContext SC) {
        createSiteUser(accsId);
        system.debug('gasdfgsdfg');
        sh_UpdateClient.job(accsId);
        IntegratorMoradas.moradaClienteUpsert(addIds);
        Integrator.contactUpsert(contIds);
        
    }
    
    public static List<Account> buildAccs(Set<Id> accsId){
        return [select Id,Numero_de_cliente__c, Name, Numero_de_contribuinte__c, Prefixo_de_contribuinte__c, Phone, BillingStreet, BillingState, BillingPostalCode, Website, BillingCountryCode, Email__c, Inativo__c, Idioma__c,
                Encomendas_canceladas__c, Tabela_de_precos__c, Escalao_Hidea__c, Mercado_de_customizacoes__c, Mercado__c, Escalao_Standard__c, Owner_aux__c, Owner.Phone, Owner.Email , Username__c, Password__c
                from Account where Id In :accsId];
    }
    
    @future(callout=true)
    public static void createSiteUser(Set<Id> accsId){
        system.debug('asdfadf');
        List<Account> accs = buildAccs(accsId);
        for(Account acc : accs){
            clientStrickerSite.ClienteUserToSite result = new clientStrickerSite.ClienteUserToSite();
            
            result.numCliente = acc.Numero_de_cliente__c != null ? acc.Numero_de_cliente__c : '';
            result.nomeEmpresa = acc.Name != null ? acc.Name : '';
            result.userName = acc.Username__c != null ? acc.Username__c : '';
            result.userPass = acc.Password__c != null ? acc.Password__c : '';
            result.nif = acc.Numero_de_contribuinte__c != null ? acc.Numero_de_contribuinte__c : '';
            result.preNIF = acc.Prefixo_de_contribuinte__c != null ? acc.Prefixo_de_contribuinte__c : '';
            result.phone = acc.Phone != null ? acc.Phone : '';
            result.morada = acc.BillingStreet != null ? acc.BillingStreet : '';
            result.local = acc.BillingState != null ? acc.BillingState : '';
            result.cod_post = acc.BillingPostalCode != null ? acc.BillingPostalCode : '';
            result.website = acc.Website != null ? acc.Website : '';
            result.pais = acc.BillingCountryCode != null ? acc.BillingCountryCode : '';
            result.email = acc.Email__c != null ? acc.Email__c : '';
            result.inativo = acc.Inativo__c != null ? acc.Inativo__c : false;
            result.enc_canceladas = acc.Encomendas_canceladas__c != null ? acc.Encomendas_canceladas__c : false;
            result.tab_precos = acc.Tabela_de_precos__c != null ? Integer.valueOf(acc.Tabela_de_precos__c) : 0;
            result.escalao_hidea = acc.Escalao_Hidea__c != null ? acc.Escalao_Hidea__c : '';
            result.idioma = acc.Idioma__c != null ? acc.Idioma__c : '';
            result.merc_cust = acc.Mercado_de_customizacoes__c != null ? acc.Mercado_de_customizacoes__c : '';
            result.merc = acc.Mercado__c != null ? acc.Mercado__c : '';
            result.esc_standard = acc.Escalao_Standard__c != null ? acc.Escalao_Standard__c : false;
            result.vend_nome = acc.Owner_aux__c != null ? acc.Owner_aux__c : '';
            result.vend_telefone = acc.Owner.Phone != null ? acc.Owner.Phone : '';
            result.vend_email = acc.Owner.Email != null ? acc.Owner.Email : '';
            result.nivel = 0;
            result.encripta = false;
            
            clientStrickerSite.stampUpSet resultCall = IntegratorSite.createSiteUser(result);
            
            system.debug(resultCall);
        }
    }
}