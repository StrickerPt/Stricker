public class c_ViewerUtilizadores {
    
    public Account acc {get;set;}
    public List<Utilizador> utilizadores {get;set;}
    public String utilizador {get;set;}
    public String newPassword {get;set;}
    public boolean sucessReset {get;set;}
    public boolean sucessInactivar {get;set;}
    public NovoUtilizador novoUser {get;set;}
    
    public boolean sucessNewUser {get;set;}
    public String newUserMessage {get;set;}
    
    public Map<Integer, String> errorMessages = new Map<Integer, String>
    {10 => Label.Username_vazio,
        11 => Label.Username_igual,
        12 => Label.Email_igual,
        13 => Label.Erro_inserir_user,
        14 => Label.OdbcException,
        15 => Label.SQLServer
        };
            
            public c_ViewerUtilizadores(ApexPages.StandardController stdCtrl){
                this.acc = buildAcc(stdCtrl.getId());
                novoUser = new NovoUtilizador();
                sucessInactivar = false;
            }
    
    public static Account buildAcc(String accId){
        return [select Id,Numero_de_cliente__c, Name, Numero_de_contribuinte__c, Prefixo_de_contribuinte__c, Phone, BillingStreet, BillingState, BillingPostalCode, Website, BillingCountryCode, Email__c, Inativo__c, 
                Encomendas_canceladas__c, Tabela_de_precos__c, Escalao_Hidea__c, Mercado_de_customizacoes__c, Mercado__c, Escalao_Standard__c, Owner_aux__c, Owner.Phone, Owner.Email 
                from Account where Id = :accId];
    }
    
    public void init(){
        try{
            novoUser = new NovoUtilizador();
            if(acc.Numero_de_cliente__c != null && acc.Numero_de_cliente__c.isNumeric()) utilizadores = IntegratorSite.consultaUtilizadores(Integer.valueOf(acc.Numero_de_cliente__c));
        }
        catch(System.CalloutException ec) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ligacao_insucesso));
        }
        Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ocorreu_um_erro));
        }
    }
    
    public void clearPass(){
        newPassword = '';
        
        system.debug(utilizador);
    }
    
    public void resetPassword(){
        try{
            sucessReset = IntegratorSite.resetPassword(utilizador, newPassword);
            system.debug(sucessReset);
        }
        catch(System.CalloutException ec) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ligacao_insucesso));
        }
        Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ocorreu_um_erro));
        }
    }
    
    public void inactivarUser(){
        try{
            sucessInactivar = IntegratorSite.disableUser(utilizador);
        }catch(Exception ex){
            sucessInactivar = false;
            newUserMessage = 'Erro';
        }
        system.debug(sucessReset);
    }
    
    public List<SelectOption> getLinguas(){
        Schema.sObjectType sobject_typec = Account.getSObjectType();
        Schema.DescribeSObjectResult sobject_describec = sobject_typec.getDescribe();
        Map<String, Schema.SObjectField> field_mapc = sobject_describec.fields.getMap();
        List<Schema.PicklistEntry> pick_list_valuesc = field_mapc.get('Idioma__c').getDescribe().getPickListValues();
        List<SelectOption> map_optionsc = new List<SelectOption>();
        map_optionsc.add(new selectOption('', '--'));
        for (Schema.PicklistEntry a : pick_list_valuesc) {
            map_optionsc.add(new selectOption(a.getValue(), a.getLabel()));
        }
        
        return map_optionsc;
    }
    
    public List<SelectOption> getAcessos(){
        List<SelectOption> map_optionsc = new List<SelectOption>();
        map_optionsc.add(new selectOption('', '--'));
        map_optionsc.add(new selectOption('0', Label.Administrador));
        map_optionsc.add(new selectOption('1', Label.Cliente_com_precos));
        map_optionsc.add(new selectOption('2', Label.Cliente_sem_precos));
        
        return map_optionsc;
    }
    
    public void submitUser(){
        try{
            clientStrickerSite.ClienteUserToSite request = createRequest(novoUser, acc);
            system.debug(request);
            
            clientStrickerSite.stampUpSet result = IntegratorSite.createSiteUser(request);
            
            sucessNewUser = result.erros == 0;
            if(!sucessNewUser){
                if(errorMessages.containsKey(result.erros)){
                    newUserMessage = errorMessages.get(result.erros);
                }else{
                    newUserMessage = result.errorMessage;
                }
            }else{
                newUserMessage = '';
            }
            system.debug(result);
        }
        catch(System.CalloutException ec) { 
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ligacao_insucesso));
        }
        Catch(Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,Label.Ocorreu_um_erro));
        }
    }
    
    public static clientStrickerSite.ClienteUserToSite createRequest(NovoUtilizador newUser, Account acc){
        clientStrickerSite.ClienteUserToSite result = new clientStrickerSite.ClienteUserToSite();
        
        result.numCliente = acc.Numero_de_cliente__c != null ? acc.Numero_de_cliente__c : '';
        result.nomeEmpresa = acc.Name != null ? acc.Name : '';
        result.userName = newUser.username != null ? newUser.username : '';
        result.userPass = newUser.password != null ? newUser.password : '';
        result.nif = acc.Numero_de_contribuinte__c != null ? acc.Numero_de_contribuinte__c : '';
        result.preNIF = acc.Prefixo_de_contribuinte__c != null ? acc.Prefixo_de_contribuinte__c : '';
        result.phone = acc.Phone != null ? acc.Phone : '';
        result.morada = acc.BillingStreet != null ? acc.BillingStreet : '';
        result.local = acc.BillingState != null ? acc.BillingState : '';
        result.cod_post = acc.BillingPostalCode != null ? acc.BillingPostalCode : '';
        result.website = acc.Website != null ? acc.Website : '';
        result.pais = acc.BillingCountryCode != null ? acc.BillingCountryCode : '';
        result.email = newUser.email != null ? newUser.email : '';
        result.inativo = acc.Inativo__c != null ? acc.Inativo__c : false;
        result.enc_canceladas = acc.Encomendas_canceladas__c != null ? acc.Encomendas_canceladas__c : false;
        result.tab_precos = Integer.valueOf(acc.Tabela_de_precos__c) != null ? Integer.valueOf(acc.Tabela_de_precos__c) : 0;
        result.escalao_hidea = acc.Escalao_Hidea__c != null ? acc.Escalao_Hidea__c : '';
        result.idioma = newUser.lingua != null ? newUser.lingua : '';
        result.merc_cust = acc.Mercado_de_customizacoes__c != null ? acc.Mercado_de_customizacoes__c : '';
        result.merc = acc.Mercado__c != null ? acc.Mercado__c : '';
        result.esc_standard = acc.Escalao_Standard__c != null ? acc.Escalao_Standard__c : false;
        result.vend_nome = acc.Owner_aux__c != null ? acc.Owner_aux__c : '';
        result.vend_telefone = acc.Owner.Phone != null ? acc.Owner.Phone : '';
        result.vend_email = acc.Owner.Email != null ? acc.Owner.Email : '';
        result.nivel = newUser.tipoDeAcesso != null ? Integer.valueOf(newUser.tipoDeAcesso) : 0;
        result.encripta = true;
        
        return result;
    }
    
    public class Utilizador{
        public String idClienteERP {get;set;}
        public String clienteUsername {get;set;}
        public String clienteEmail {get;set;}
        public Boolean activo {get;set;}
        public Boolean podeEncomendar {get;set;}
        
        public Utilizador(Decimal idClienteERP, String clienteUsername, String clienteEmail, Boolean activo, Boolean podeEncomendar){
            this.idClienteERP = String.valueOf(idClienteERP);
            this.clienteUsername = clienteUsername;
            this.clienteEmail = clienteEmail;
            this.activo = activo;
            this.podeEncomendar = podeEncomendar;
        }
    }
    
    public class NovoUtilizador{
        public String username {get;set;}
        public String password {get;set;}
        public String lingua {get;set;}
        public String tipoDeAcesso {get;set;}
        public String email {get;set;}
        
        public NovoUtilizador(){}
        
    }
}