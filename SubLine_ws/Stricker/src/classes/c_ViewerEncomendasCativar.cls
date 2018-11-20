public class c_ViewerEncomendasCativar {
    public User user {get;set;}
    public List<Encomenda> encomendas {get;set;}
    public String oppToSearch {get;set;}
    public Id resultId {get;set;}
    
    public c_ViewerEncomendasCativar(){

        user =[Select Id, Codigo_de_utilizador__c, Profile.Name From User Where Id = :UserInfo.getUserId()];
        Integrator.servico.timeout_x = 120000;
        try{
            encomendas = Integrator.encomendasPorCativar(user.Profile.Name == 'Comercial' ? user.Codigo_de_utilizador__c : '%');
        }catch(Exception ex){}
    }
    
    public class Encomenda{
        
        public String Descricao {get;set;}
        public String Comercial {get;set;}
        public String Referencia {get;set;}
        public Decimal Quantidade {get;set;}
        public Boolean Cativo {get;set;}
        public String NumDossier {get;set;}
        public String NumFolhaObra {get;set;}
        public Decimal StockExistente {get;set;}
        
        public Encomenda(String Descricao, String Comercial, String Referencia, Decimal Quantidade, Boolean Cativo,
                         String NumDossier, String NumFolhaObra, Decimal StockExistente){
            this.Descricao = Descricao;
            this.Comercial = Comercial;
            this.Referencia = Referencia;
            this.Quantidade = Quantidade;
            this.Cativo = Cativo;
            this.NumDossier = NumDossier;
            this.NumFolhaObra = NumFolhaObra;
            this.StockExistente = StockExistente;
        }
    }
	
    public void getOppId(){
        if(oppToSearch != null){
            List<Opportunity> opps = [Select Id From Opportunity Where Referencia_PHC__c = :oppToSearch];
            if(!opps.isEmpty()){
                resultId = opps.get(0).Id;
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Não foram encontradas oportunidades com essa referencia.'));
            }
            oppToSearch = null;
        }
    }
    
    public void cativarStock(){
        if(oppToSearch != null){
            List<Opportunity> opps = [Select Id, Versao_enviada__c, (Select id From OpportunityLineItems) From Opportunity Where Referencia_PHC__c = :oppToSearch];
            if(!opps.isEmpty()){
                for(OpportunityLineItem oli: opps.get(0).OpportunityLineItems){
                    oli.Stock_cativo__c = true;
                }
                if(!opps.get(0).OpportunityLineItems.isEmpty()) update opps.get(0).OpportunityLineItems; 
                //RP 07-11-2018 incrementacao versao enviada
                checkRecursive.runFalse();
                if(opps.get(0).Versao_enviada__c != null){
                    opps.get(0).Versao_enviada__c = opps.get(0).Versao_enviada__c + 1;
                }else{
                    opps.get(0).Versao_enviada__c = 1;
                }
                update opps.get(0);
                Integrator.actDossier(new Set<Id>{opps.get(0).Id});
            }else{
                ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.WARNING,'Não foram encontradas oportunidades com essa referencia.'));
            }
        }
    }
}